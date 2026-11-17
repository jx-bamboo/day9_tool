class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action
      t.references :auditable, polymorphic: true
      t.string :ip_address
      t.json :metadata

      t.timestamps
    end
  end
end
