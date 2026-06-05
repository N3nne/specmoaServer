import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import '../models/community_qna_data.dart';
import '../models/home_data.dart';
import '../services/community_qna_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_page.dart';

class CommunityQuestionDetailScreen extends StatefulWidget {
  const CommunityQuestionDetailScreen({
    required this.post,
    super.key,
  });

  final HomeCommunityPost post;

  @override
  State<CommunityQuestionDetailScreen> createState() =>
      _CommunityQuestionDetailScreenState();
}

class _CommunityQuestionDetailScreenState
    extends State<CommunityQuestionDetailScreen> {
  final _qnaClient = const CommunityQnaApiClient();
  final _commentController = TextEditingController();
  late Future<CommunityQnaAnswerPage> _answersFuture;
  String? _acceptedAnswerId;

  @override
  void initState() {
    super.initState();
    _answersFuture = _qnaClient.fetchAnswers(widget.post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate:
                  _QuestionHeaderDelegate(onBack: Navigator.of(context).pop),
            ),
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.x4),
                    _QuestionCard(post: widget.post),
                    const SizedBox(height: AppSpacing.x4),
                    _AnswersSection(
                      future: _answersFuture,
                      acceptedAnswerId: _acceptedAnswerId,
                      currentUserId: AuthScope.of(context).user?.id ?? '',
                      onAccept: _acceptAnswer,
                    ),
                    const SizedBox(height: 104),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _CommentComposer(
          controller: _commentController,
          onSend: _createAnswer,
        ),
      ),
    );
  }

  Future<void> _createAnswer() async {
    final body = _commentController.text.trim();
    if (body.length < 2) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final userId = AuthScope.of(context).user?.id ?? '';

    try {
      await _qnaClient.createAnswer(
        postId: widget.post.id,
        userId: userId,
        body: body,
      );
      _commentController.clear();
      setState(() {
        _answersFuture = _qnaClient.fetchAnswers(widget.post.id);
      });
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _acceptAnswer(CommunityQnaAnswer answer) async {
    final messenger = ScaffoldMessenger.of(context);
    final userId = AuthScope.of(context).user?.id ?? '';

    try {
      final accepted = await _qnaClient.acceptAnswer(
        postId: widget.post.id,
        answerId: answer.id,
        userId: userId,
      );
      setState(() {
        _acceptedAnswerId = accepted.id;
        _answersFuture = _qnaClient.fetchAnswers(widget.post.id);
      });
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _QuestionHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _QuestionHeaderDelegate({required this.onBack});

  final VoidCallback onBack;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.surface.withValues(alpha: 0.94),
      child: ResponsivePage(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
        child: Row(
          children: [
            IconButton(
              tooltip: '뒤로가기',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: AppSpacing.x1),
            Text(
              '질문 상세',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _QuestionHeaderDelegate oldDelegate) =>
      oldDelegate.onBack != onBack;
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.post});

  final HomeCommunityPost post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Q.',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CertificationBadge(label: post.certificationName),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      post.title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.34,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            '${post.authorName} · 30분 전 · 조회 ${post.viewCount}',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            post.body.trim().isEmpty ? '작성된 본문이 없습니다.' : post.body,
            style: textTheme.bodyMedium?.copyWith(height: 1.62),
          ),
          const SizedBox(height: AppSpacing.x5),
          Row(
            children: [
              _ActionPill(
                icon: Icons.favorite_rounded,
                label: '${post.likeCount}',
                color: AppColors.error,
              ),
              const SizedBox(width: AppSpacing.x2),
              _ActionPill(
                icon: Icons.mode_comment_outlined,
                label: '${post.commentCount}',
                color: AppColors.onSurfaceVariant,
              ),
              const Spacer(),
              IconButton(
                tooltip: '저장',
                onPressed: () {},
                icon: const Icon(Icons.bookmark_border_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswersSection extends StatelessWidget {
  const _AnswersSection({
    required this.future,
    required this.acceptedAnswerId,
    required this.currentUserId,
    required this.onAccept,
  });

  final Future<CommunityQnaAnswerPage> future;
  final String? acceptedAnswerId;
  final String currentUserId;
  final ValueChanged<CommunityQnaAnswer> onAccept;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<CommunityQnaAnswerPage>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.x8),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final items = snapshot.data?.items ?? const [];
        if (items.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.x5),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: Text(
              '아직 댓글이 없습니다.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          );
        }

        final accepted = items.where((item) {
          return item.accepted || item.id == acceptedAnswerId;
        }).toList();
        final comments = items.where((item) {
          return !item.accepted && item.id != acceptedAnswerId;
        }).toList();

        return Column(
          children: [
            for (final answer in accepted) ...[
              _AnswerCard(answer: answer, accepted: true, onAccept: onAccept),
              const SizedBox(height: AppSpacing.x4),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.x5),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '댓글 ${items.length}',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  for (final answer in comments) ...[
                    _AnswerRow(
                      answer: answer,
                      currentUserId: currentUserId,
                      onAccept: onAccept,
                    ),
                    if (answer != comments.last)
                      const SizedBox(height: AppSpacing.x4),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.answer,
    required this.accepted,
    required this.onAccept,
  });

  final CommunityQnaAnswer answer;
  final bool accepted;
  final ValueChanged<CommunityQnaAnswer> onAccept;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'A.',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: _AnswerAuthorLine(
                  authorName: answer.authorName,
                  certified: answer.authorCertified,
                  textStyle: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const _VerifiedBadge(label: '채택 답변'),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(answer.body,
              style: textTheme.bodyMedium?.copyWith(height: 1.62)),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.answer,
    required this.currentUserId,
    required this.onAccept,
  });

  final CommunityQnaAnswer answer;
  final String currentUserId;
  final ValueChanged<CommunityQnaAnswer> onAccept;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnswerAuthorLine(
                authorName: answer.authorName,
                certified: answer.authorCertified,
                textStyle: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(answer.body,
                  style: textTheme.bodySmall?.copyWith(height: 1.5)),
              const SizedBox(height: AppSpacing.x2),
              if (answer.authorId != currentUserId) ...[
                const SizedBox(height: AppSpacing.x2),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => onAccept(answer),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('A 카드 선정'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AnswerAuthorLine extends StatelessWidget {
  const _AnswerAuthorLine({
    required this.authorName,
    required this.certified,
    required this.textStyle,
  });

  final String authorName;
  final bool certified;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
        if (certified) ...[
          const SizedBox(width: AppSpacing.x1),
          Tooltip(
            message: '취득 인증 사용자',
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 3),
                  Text(
                    '인증',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '댓글을 입력하세요',
                prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          IconButton.filled(
            tooltip: '등록',
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _CertificationBadge extends StatelessWidget {
  const _CertificationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.primary,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.x1),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}
