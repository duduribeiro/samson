Stage.class_eval do
  serialize :next_stage_ids, Array

  def next_stage
    return Stage.find(next_stage_ids.first) unless next_stage_ids.empty?
    stages = project.stages.to_a
    stages[stages.index(self) + 1]
  end
end
