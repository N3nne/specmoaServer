import { MigrationInterface, QueryRunner, Table, TableForeignKey, TableIndex } from 'typeorm';

export class AddAuthSessions1792195200000 implements MigrationInterface {
  async up(queryRunner: QueryRunner) {
    await queryRunner.createTable(new Table({
      name: 'auth_sessions',
      columns: [
        { name: 'id', type: 'uuid', isPrimary: true, default: 'gen_random_uuid()' },
        { name: 'userId', type: 'uuid' },
        { name: 'tokenHash', type: 'varchar', length: '64' },
        { name: 'expiresAt', type: 'timestamptz' },
        { name: 'revokedAt', type: 'timestamptz', isNullable: true },
        { name: 'createdAt', type: 'timestamptz', default: 'now()' },
      ],
      indices: [new TableIndex({ name: 'IDX_auth_sessions_user_expiry', columnNames: ['userId', 'expiresAt'] })],
      foreignKeys: [new TableForeignKey({ columnNames: ['userId'], referencedTableName: 'users', referencedColumnNames: ['id'], onDelete: 'CASCADE' })],
    }), true);
  }

  async down() {
    throw new Error('Dropping authentication sessions logs out users. Restore a verified backup instead.');
  }
}
