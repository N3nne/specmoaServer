import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CertificationEntity } from '../certifications/entities/certification.entity';
import {
  UserCertificationEntity,
  UserCertificationStatus,
} from '../certifications/entities/user-certification.entity';
import { TagEntity } from '../certifications/entities/tag.entity';
import { UsersService } from '../users/users.service';
import { CommunityQnaAnswerEntity } from './entities/community-qna-answer.entity';
import {
  CommunityQnaPostEntity,
  CommunityQnaStatus,
} from './entities/community-qna-post.entity';
import {
  SuccessStoryEntity,
  SuccessStoryStatus,
} from './entities/success-story.entity';

export type CommunityQnaListQuery = {
  tagId?: string;
  tag?: string;
  q?: string;
  certificationId?: string;
  sort?: string;
  limit?: number;
  offset?: number;
};

export type SuccessStoryListQuery = {
  q?: string;
  certificationId?: string;
  sort?: string;
  limit?: number;
  offset?: number;
};

export type CreateQnaPostInput = {
  certificationId?: string;
  title?: string;
  body?: string;
  tags?: string[];
  isAnonymous?: boolean;
};

export type CreateQnaAnswerInput = {
  body?: string;
};

export type CreateSuccessStoryInput = {
  certificationId?: string;
  title?: string;
  subtitle?: string;
  body?: string;
  studyPeriodDays?: number;
  studyMethod?: string;
  score?: string;
  examAttempt?: string;
};

@Injectable()
export class CommunityService {
  constructor(
    @InjectRepository(CommunityQnaPostEntity)
    private readonly qnaPosts: Repository<CommunityQnaPostEntity>,
    @InjectRepository(CommunityQnaAnswerEntity)
    private readonly qnaAnswers: Repository<CommunityQnaAnswerEntity>,
    @InjectRepository(SuccessStoryEntity)
    private readonly successStories: Repository<SuccessStoryEntity>,
    @InjectRepository(CertificationEntity)
    private readonly certifications: Repository<CertificationEntity>,
    @InjectRepository(UserCertificationEntity)
    private readonly userCertifications: Repository<UserCertificationEntity>,
    @InjectRepository(TagEntity)
    private readonly tags: Repository<TagEntity>,
    private readonly users: UsersService,
  ) {}

  async findQnaPosts(query: CommunityQnaListQuery) {
    const limit = Math.min(Math.max(query.limit ?? 20, 1), 50);
    const offset = Math.max(query.offset ?? 0, 0);
    const builder = this.qnaPosts
      .createQueryBuilder('post')
      .leftJoinAndSelect('post.author', 'author')
      .leftJoinAndSelect('post.certification', 'certification')
      .leftJoinAndSelect('post.tagMappings', 'tagMapping')
      .leftJoinAndSelect('tagMapping.tag', 'tag')
      .leftJoinAndSelect('post.answers', 'answer')
      .leftJoinAndSelect('answer.author', 'answerAuthor')
      .where('post.status != :hiddenStatus', { hiddenStatus: CommunityQnaStatus.HIDDEN })
      .take(limit)
      .skip(offset);

    if (query.sort === 'popular') {
      builder.orderBy('post.likeCount', 'DESC').addOrderBy('post.answerCount', 'DESC');
    } else if (query.sort === 'answers') {
      builder.orderBy('post.answerCount', 'DESC').addOrderBy('post.likeCount', 'DESC');
    } else {
      builder.orderBy('post.createdAt', 'DESC');
    }

    if (query.q?.trim()) {
      builder.andWhere(
        '(post.title ILIKE :keyword OR post.body ILIKE :keyword OR certification.name ILIKE :keyword)',
        { keyword: `%${query.q.trim()}%` },
      );
    }

    if (query.certificationId) {
      builder.andWhere('certification.id = :certificationId', {
        certificationId: query.certificationId,
      });
    }

    if (query.tagId) {
      builder.andWhere((qb) => {
        const subQuery = qb
          .subQuery()
          .select('filteredPost.id')
          .from(CommunityQnaPostEntity, 'filteredPost')
          .innerJoin('filteredPost.tagMappings', 'filteredMapping')
          .innerJoin('filteredMapping.tag', 'filteredTag')
          .where('filteredTag.id = :tagId')
          .getQuery();

        return `post.id in ${subQuery}`;
      });
      builder.setParameter('tagId', query.tagId);
    }

    if (query.tag) {
      builder.andWhere((qb) => {
        const subQuery = qb
          .subQuery()
          .select('filteredPost.id')
          .from(CommunityQnaPostEntity, 'filteredPost')
          .innerJoin('filteredPost.tagMappings', 'filteredMapping')
          .innerJoin('filteredMapping.tag', 'filteredTag')
          .where('filteredTag.name = :tagName')
          .getQuery();

        return `post.id in ${subQuery}`;
      });
      builder.setParameter('tagName', query.tag);
    }

    const [posts, totalCount] = await builder.getManyAndCount();
    const items =
      posts.length > 0
        ? posts.map((post) => this.toQnaItem(post))
        : this.dummyQnaItems(query, limit);

    return {
      totalCount: posts.length > 0 ? totalCount : items.length,
      limit,
      offset,
      items,
    };
  }

  private toQnaItem(post: CommunityQnaPostEntity) {
    const isAnonymous = post.metadata?.isAnonymous === true;

    return {
      id: post.id,
      title: post.title,
      body: post.body,
      status: post.status,
      viewCount: post.viewCount,
      likeCount: post.likeCount,
      answerCount: post.answerCount,
      acceptedAnswer: this.findAcceptedAnswer(post),
      author: post.author && !isAnonymous
        ? {
            id: post.author.id,
            displayName: post.author.displayName,
          }
        : undefined,
      certification: post.certification
        ? {
            id: post.certification.id,
            name: post.certification.name,
          }
        : undefined,
      tags:
        post.tagMappings?.length > 0
          ? post.tagMappings.map((mapping) => ({
              id: mapping.tag.id,
              type: mapping.tag.type,
              name: mapping.tag.name,
              slug: mapping.tag.slug,
            }))
          : post.tags?.map((tag) => ({
              id: tag,
              type: 'custom',
              name: tag,
              slug: tag,
            })),
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      dummy: false,
    };
  }

  private findAcceptedAnswer(post: CommunityQnaPostEntity) {
    if (!post.acceptedAnswerId || !post.answers?.length) {
      return undefined;
    }

    const answer = post.answers.find((item) => item.id === post.acceptedAnswerId);
    return answer ? this.toQnaAnswerItem(answer, post.acceptedAnswerId) : undefined;
  }

  private toQnaAnswerItem(
    answer: CommunityQnaAnswerEntity,
    acceptedAnswerId?: string,
    authorCertified = false,
  ) {
    return {
      id: answer.id,
      body: answer.body,
      likeCount: answer.likeCount,
      authorCertified,
      author: answer.author
        ? {
            id: answer.author.id,
            displayName: answer.author.displayName,
          }
        : undefined,
      accepted: answer.id === acceptedAnswerId,
      createdAt: answer.createdAt,
      updatedAt: answer.updatedAt,
      dummy: false,
    };
  }

  private async isAnswerAuthorCertified(
    answer: CommunityQnaAnswerEntity,
    certificationId?: string,
  ) {
    if (!answer.author?.id || !certificationId) {
      return false;
    }

    const row = await this.userCertifications.findOne({
      where: {
        user: { id: answer.author.id },
        certification: { id: certificationId },
        status: UserCertificationStatus.CERTIFIED,
      },
    });

    return row != null;
  }

  private dummyQnaItems(query: CommunityQnaListQuery, limit: number) {
    const certificationName = query.q?.trim() || '정보처리기사';
    return Array.from({ length: limit }, (_, index) => ({
      id: `dummy-qna-${index + 1}`,
      title:
        index === 0
          ? `${certificationName} 실기 2주 준비 가능할까요?`
          : `${certificationName} 준비 질문 ${index + 1}`,
      body: '핵심 개념과 기출 위주로 준비해도 괜찮을지 궁금합니다.',
      status: CommunityQnaStatus.OPEN,
      viewCount: 120 - index * 7,
      likeCount: 12 - Math.min(index, 8),
      answerCount: 2 + (index % 4),
      acceptedAnswer: {
        id: `dummy-answer-${index + 1}`,
        body: '핵심 개념과 최근 기출을 먼저 정리하면 충분히 준비할 수 있어요.',
        likeCount: 0,
        author: { id: 'dummy-mentor', displayName: '스펙모아 멘토' },
        accepted: true,
        createdAt: new Date().toISOString(),
        dummy: true,
      },
      author: { id: 'dummy-author', displayName: '스펙모아' },
      certification: { id: query.certificationId ?? '', name: certificationName },
      tags: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      dummy: true,
    }));
  }

  async createQnaPost(userId: string | undefined, input: CreateQnaPostInput) {
    const title = input.title?.trim();
    const body = input.body?.trim();

    if (!input.certificationId) {
      throw new BadRequestException('certificationId is required.');
    }
    if (!title || title.length < 4) {
      throw new BadRequestException('title must be at least 4 characters.');
    }
    if (!body || body.length < 10) {
      throw new BadRequestException('body must be at least 10 characters.');
    }

    const [user, certification] = await Promise.all([
      this.users.getRequestUser(userId),
      this.certifications.findOneBy({ id: input.certificationId }),
    ]);

    if (!certification) {
      throw new NotFoundException(`Certification ${input.certificationId} was not found.`);
    }

    const tags = Array.isArray(input.tags)
      ? input.tags
          .map((tag) => String(tag).trim())
          .filter((tag) => tag.length > 0)
          .slice(0, 8)
      : [];

    const post = await this.qnaPosts.save(
      this.qnaPosts.create({
        author: user,
        certification,
        title,
        body,
        tags,
        status: CommunityQnaStatus.OPEN,
        metadata: {
          isAnonymous: input.isAnonymous === true,
        },
      }),
    );

    return this.toQnaItem({
      ...post,
      author: input.isAnonymous ? undefined : user,
      certification,
      tagMappings: [],
    } as CommunityQnaPostEntity);
  }

  async recordQnaView(id: string) {
    const post = await this.qnaPosts.findOne({
      where: { id },
      relations: {
        author: true,
        certification: true,
        answers: { author: true },
        tagMappings: { tag: true },
      },
    });

    if (!post || post.status === CommunityQnaStatus.HIDDEN) {
      throw new NotFoundException(`QnA post ${id} was not found.`);
    }

    await this.qnaPosts.increment({ id }, 'viewCount', 1);
    post.viewCount += 1;
    return this.toQnaItem(post);
  }

  async findQnaAnswers(postId: string) {
    const post = await this.qnaPosts.findOne({
      where: { id: postId },
      relations: { certification: true },
    });
    if (!post || post.status === CommunityQnaStatus.HIDDEN) {
      throw new NotFoundException(`QnA post ${postId} was not found.`);
    }

    const answers = await this.qnaAnswers.find({
      where: { post: { id: postId } },
      relations: { author: true },
      order: { createdAt: 'ASC' },
    });

    const items = await Promise.all(
      answers.map(async (answer) =>
        this.toQnaAnswerItem(
          answer,
          post.acceptedAnswerId,
          await this.isAnswerAuthorCertified(answer, post.certification?.id),
        ),
      ),
    );

    return { items };
  }

  async createQnaAnswer(
    postId: string,
    userId: string | undefined,
    input: CreateQnaAnswerInput,
  ) {
    const body = input.body?.trim();
    if (!body || body.length < 2) {
      throw new BadRequestException('body must be at least 2 characters.');
    }

    const [post, user] = await Promise.all([
      this.qnaPosts.findOne({
        where: { id: postId },
        relations: { certification: true },
      }),
      this.users.getRequestUser(userId),
    ]);

    if (!post || post.status === CommunityQnaStatus.HIDDEN) {
      throw new NotFoundException(`QnA post ${postId} was not found.`);
    }

    const answer = await this.qnaAnswers.save(
      this.qnaAnswers.create({
        post,
        author: user,
        body,
      }),
    );
    await this.qnaPosts.increment({ id: postId }, 'answerCount', 1);
    post.answerCount += 1;

    return this.toQnaAnswerItem(
      { ...answer, author: user } as CommunityQnaAnswerEntity,
      post.acceptedAnswerId,
      await this.isAnswerAuthorCertified(
        { ...answer, author: user } as CommunityQnaAnswerEntity,
        post.certification?.id,
      ),
    );
  }

  async acceptQnaAnswer(postId: string, answerId: string, userId?: string) {
    const post = await this.qnaPosts.findOne({
      where: { id: postId },
      relations: { author: true, certification: true },
    });
    if (!post || post.status === CommunityQnaStatus.HIDDEN) {
      throw new NotFoundException(`QnA post ${postId} was not found.`);
    }

    if (userId && post.author?.id && post.author.id !== userId) {
      throw new BadRequestException('Only the post author can accept an answer.');
    }

    const answer = await this.qnaAnswers.findOne({
      where: { id: answerId, post: { id: postId } },
      relations: { author: true },
    });
    if (!answer) {
      throw new NotFoundException(`QnA answer ${answerId} was not found.`);
    }
    if (userId && answer.author?.id === userId) {
      throw new BadRequestException('You cannot accept your own answer.');
    }

    post.acceptedAnswerId = answer.id;
    post.status = CommunityQnaStatus.ANSWERED;
    await this.qnaPosts.save(post);

    return this.toQnaAnswerItem(
      answer,
      post.acceptedAnswerId,
      await this.isAnswerAuthorCertified(answer, post.certification?.id),
    );
  }

  async findAvailableTags() {
    const tags = await this.tags
      .createQueryBuilder('tag')
      .innerJoin('tag.qnaPostMappings', 'mapping')
      .select('tag.id', 'id')
      .addSelect('tag.type', 'type')
      .addSelect('tag.name', 'name')
      .addSelect('tag.slug', 'slug')
      .addSelect('count(mapping.id)::int', 'postCount')
      .groupBy('tag.id')
      .orderBy('count(mapping.id)', 'DESC')
      .addOrderBy('tag.name', 'ASC')
      .getRawMany();

    return tags;
  }

  async findSuccessStories(query: SuccessStoryListQuery) {
    const limit = Math.min(Math.max(query.limit ?? 20, 1), 50);
    const offset = Math.max(query.offset ?? 0, 0);
    const builder = this.successStories
      .createQueryBuilder('story')
      .leftJoinAndSelect('story.author', 'author')
      .leftJoinAndSelect('story.certification', 'certification')
      .where('story.status = :status', { status: SuccessStoryStatus.PUBLISHED })
      .take(limit)
      .skip(offset);

    if (query.sort === 'latest') {
      builder.orderBy('story.createdAt', 'DESC');
    } else if (query.sort === 'comments') {
      builder.orderBy('story.viewCount', 'DESC').addOrderBy('story.likeCount', 'DESC');
    } else {
      builder.orderBy('story.likeCount', 'DESC').addOrderBy('story.viewCount', 'DESC');
    }

    if (query.q?.trim()) {
      builder.andWhere(
        '(story.title ILIKE :keyword OR story.body ILIKE :keyword OR certification.name ILIKE :keyword)',
        { keyword: `%${query.q.trim()}%` },
      );
    }

    if (query.certificationId) {
      builder.andWhere('certification.id = :certificationId', {
        certificationId: query.certificationId,
      });
    }

    const [stories, totalCount] = await builder.getManyAndCount();
    const items =
      stories.length > 0
        ? stories.map((story) => this.toSuccessStoryItem(story))
        : this.dummySuccessStoryItems(query, limit);

    return {
      totalCount: stories.length > 0 ? totalCount : items.length,
      limit,
      offset,
      items,
    };
  }

  async createSuccessStory(userId: string | undefined, input: CreateSuccessStoryInput) {
    const title = input.title?.trim();
    const body = input.body?.trim();

    if (!input.certificationId) {
      throw new BadRequestException('certificationId is required.');
    }
    if (!title || title.length < 4) {
      throw new BadRequestException('title must be at least 4 characters.');
    }
    if (!body || body.length < 10) {
      throw new BadRequestException('body must be at least 10 characters.');
    }

    const [user, certification] = await Promise.all([
      this.users.getRequestUser(userId),
      this.certifications.findOneBy({ id: input.certificationId }),
    ]);

    if (!certification) {
      throw new NotFoundException(`Certification ${input.certificationId} was not found.`);
    }

    const story = await this.successStories.save(
      this.successStories.create({
        author: user,
        certification,
        title,
        body,
        studyPeriodDays: input.studyPeriodDays,
        examAttempt: input.examAttempt?.trim() || '합격',
        status: SuccessStoryStatus.PUBLISHED,
        metadata: {
          subtitle: input.subtitle?.trim(),
          studyMethod: input.studyMethod?.trim(),
          score: input.score?.trim(),
        },
      }),
    );

    return this.toSuccessStoryItem({
      ...story,
      author: user,
      certification,
    } as SuccessStoryEntity);
  }

  async recordSuccessStoryView(id: string) {
    const story = await this.successStories.findOne({
      where: { id, status: SuccessStoryStatus.PUBLISHED },
      relations: { author: true, certification: true },
    });

    if (!story) {
      throw new NotFoundException(`Success story ${id} was not found.`);
    }

    await this.successStories.increment({ id }, 'viewCount', 1);
    story.viewCount += 1;
    return this.toSuccessStoryItem(story);
  }

  private toSuccessStoryItem(story: SuccessStoryEntity) {
    const metadata = story.metadata ?? {};
    const subtitle = typeof metadata.subtitle === 'string' ? metadata.subtitle : '';
    const studyMethod =
      typeof metadata.studyMethod === 'string' ? metadata.studyMethod : '';
    const score = typeof metadata.score === 'string' ? metadata.score : '';

    return {
      id: story.id,
      title: story.title,
      body: story.body,
      subtitle,
      studyMethod,
      score,
      studyPeriodDays: story.studyPeriodDays,
      examAttempt: story.examAttempt,
      passedOn: story.passedOn,
      viewCount: story.viewCount,
      likeCount: story.likeCount,
      commentCount: 0,
      author: story.author
        ? {
            id: story.author.id,
            displayName: story.author.displayName,
          }
        : undefined,
      certification: story.certification
        ? {
            id: story.certification.id,
            name: story.certification.name,
          }
        : undefined,
      createdAt: story.createdAt,
      updatedAt: story.updatedAt,
      dummy: false,
    };
  }

  private dummySuccessStoryItems(query: SuccessStoryListQuery, limit: number) {
    const certificationName = query.q?.trim() || '정보처리기사';
    return Array.from({ length: limit }, (_, index) => ({
      id: `dummy-success-story-${index + 1}`,
      title: index === 0 ? `${certificationName} 3주 합격 가이드` : `${certificationName} 합격 후기 ${index + 1}`,
      body: '기출 반복과 핵심 개념 정리로 단기간에 합격한 후기입니다.',
      subtitle: '통계 표기자도 가능한 데이터 분석',
      studyMethod: '이론 1회독 + 기출 반복',
      score: '82점',
      studyPeriodDays: 21 + index,
      examAttempt: '초시',
      passedOn: undefined,
      viewCount: 320 - index * 14,
      likeCount: 45 - Math.min(index * 2, 18),
      commentCount: 18 - Math.min(index, 10),
      author: { id: 'dummy-author', displayName: '스펙모아' },
      certification: { id: query.certificationId ?? '', name: certificationName },
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      dummy: true,
    }));
  }
}
