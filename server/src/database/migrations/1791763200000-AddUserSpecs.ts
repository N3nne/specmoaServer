import { MigrationInterface, QueryRunner, Table, TableColumn, TableForeignKey, TableIndex } from 'typeorm';

export class AddUserSpecs1791763200000 implements MigrationInterface {
  async up(queryRunner: QueryRunner) {
    await queryRunner.createTable(new Table({
      name: 'user_specs',
      columns: [
        { name: 'id', type: 'uuid', isPrimary: true, default: 'gen_random_uuid()' },
        { name: 'userId', type: 'uuid' },
        { name: 'type', type: 'varchar' },
        { name: 'title', type: 'text', isNullable: true },
        { name: 'data', type: 'jsonb', default: "'{}'::jsonb" },
        { name: 'certificationId', type: 'uuid', isNullable: true },
        { name: 'legacyUserCertificationId', type: 'uuid', isNullable: true, isUnique: true },
        { name: 'createdAt', type: 'timestamptz', default: 'now()' },
        { name: 'updatedAt', type: 'timestamptz', default: 'now()' },
      ],
      foreignKeys: [
        new TableForeignKey({ columnNames: ['userId'], referencedTableName: 'users', referencedColumnNames: ['id'], onDelete: 'CASCADE' }),
        new TableForeignKey({ columnNames: ['certificationId'], referencedTableName: 'certifications', referencedColumnNames: ['id'], onDelete: 'SET NULL' }),
      ],
    }), true);
    await queryRunner.createIndex('user_specs', new TableIndex({ name: 'IDX_user_specs_owner_type_created', columnNames: ['userId', 'type', 'createdAt'] }));
    const schema = queryRunner.connection.options.type === 'postgres' ? queryRunner.connection.options.schema || 'public' : 'public';
    const quote = (value: string) => `"${value.replace(/"/g, '""')}"`;
    const table = (name: string) => `${quote(schema)}.${quote(name)}`;
    // Copy only acquired records. The original tables, notes and preparing records remain untouched.
    if (await queryRunner.hasTable('user_certifications')) {
      await queryRunner.query(`
        INSERT INTO ${table('user_specs')} ("userId", "type", "title", "data", "certificationId", "legacyUserCertificationId", "createdAt", "updatedAt")
        SELECT uc."userId", 'certification', c."name",
          jsonb_strip_nulls(jsonb_build_object('certificationId', c."id", 'name', c."name", 'issuer', c."organization", 'acquiredOn', uc."certifiedOn", 'certificateNumber', uc."certificateNumber")),
          c."id", uc."id", uc."createdAt", uc."updatedAt"
        FROM ${table('user_certifications')} uc
        LEFT JOIN ${table('certifications')} c ON c."id" = uc."certificationId"
        WHERE uc."status" = 'certified'
        ON CONFLICT ("legacyUserCertificationId") DO NOTHING
      `);
    }
    if (await queryRunner.hasTable('study_sessions')) {
      if (!(await queryRunner.hasColumn('study_sessions', 'specId'))) {
        await queryRunner.addColumn('study_sessions', new TableColumn({ name: 'specId', type: 'uuid', isNullable: true }));
        await queryRunner.createForeignKey('study_sessions', new TableForeignKey({ columnNames: ['specId'], referencedTableName: 'user_specs', referencedColumnNames: ['id'], onDelete: 'CASCADE' }));
      }
      // Ambiguous legacy associations stay unchanged instead of selecting an arbitrary duplicate.
      await queryRunner.query(`UPDATE ${table('study_sessions')} session SET "specId" = owned.id::uuid
        FROM (SELECT "userId", "certificationId", MIN(id::text) id FROM ${table('user_specs')}
          WHERE "certificationId" IS NOT NULL GROUP BY "userId", "certificationId" HAVING COUNT(*) = 1) owned
        WHERE session."userId" = owned."userId" AND session."certificationId" = owned."certificationId" AND session."specId" IS NULL`);
    }
  }

  async down() {
    throw new Error('User specs may contain user data. Restore a verified backup instead of dropping this table.');
  }
}
