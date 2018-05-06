class CreateLearns < ActiveRecord::Migration[5.1]
  def change
    create_table :learns do |t|
      t.string :fileName
      t.integer :datasetId
      t.string :modelId
      t.integer :lavels
      t.integer :examples
      t.integer :testSplitSize
      t.integer :trainSplitSize
      t.string :trainingTime
      t.string :lastEpochDone
      t.string :datasetLoadTime
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
