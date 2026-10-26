import { MigrationInterface, QueryRunner, Table, TableIndex } from 'typeorm';

export class AddJobPostings1792627200000 implements MigrationInterface {
  async up(queryRunner: QueryRunner) {
    const column = (name: string, type = 'varchar', isNullable = false) => ({ name, type, isNullable });
    await queryRunner.createTable(new Table({
      name: 'job_postings',
      columns: [
        { name: 'id', type: 'uuid', isPrimary: true, default: 'gen_random_uuid()' },
        column('source'), column('synthetic', 'boolean'), column('notice', 'text'), column('datasetVersion', 'varchar', true),
        column('externalId'), column('companyName'), column('title'), column('occupation'), column('region'), column('employmentType'),
        column('educationLevel', 'varchar', true), column('experienceLevel', 'varchar', true), column('minExperienceMonths', 'int', true),
        column('salaryText', 'text', true), { name: 'keywords', type: 'jsonb', default: "'[]'::jsonb" },
        column('postedAt', 'timestamptz'), column('opensAt', 'timestamptz'), column('closesAt', 'timestamptz', true),
        column('active', 'boolean'), column('sourceUrl', 'text', true), column('description', 'text', true), column('requirements', 'jsonb', true),
        column('fetchedAt', 'timestamptz'),
        { name: 'createdAt', type: 'timestamptz', default: 'now()' },
        { name: 'updatedAt', type: 'timestamptz', default: 'now()' },
      ],
      indices: [
        new TableIndex({ name: 'UQ_job_postings_source_external', columnNames: ['source', 'externalId'], isUnique: true }),
        new TableIndex({ name: 'IDX_job_postings_source_posted', columnNames: ['source', 'postedAt'] }),
      ],
    }), true);
  }

  async down() {
    throw new Error('Job postings may contain sourced data. Restore a verified backup instead of dropping the table.');
  }
}
