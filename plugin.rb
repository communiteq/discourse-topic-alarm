# name: discourse-topic-alarm
# about: Allows users to set an alarm on a topic
# version: 0.1
# authors: Communiteq

enabled_site_setting :topic_alarm_enabled

require_relative 'lib/discourse_topic_alarm/engine'

after_initialize do
  register_svg_icon("bell")
  register_svg_icon("far-bell")

  require_relative "app/controllers/discourse_topic_alarm/topic_alarm_controller"
  require_relative "app/jobs/scheduled/topic_alarm_checker"

  add_to_class(:user, :can_set_topic_alarm?) do
    return false unless SiteSetting.topic_alarm_groups.present?
    allowed_group_ids = SiteSetting.topic_alarm_groups.split('|').map(&:to_i)
    (group_ids & allowed_group_ids).any?
  end

  add_to_class(:guardian, :can_set_topic_alarm?) do
    user && user.can_set_topic_alarm?
  end

  add_to_serializer(:current_user, :can_set_topic_alarm) do
    object.can_set_topic_alarm?
  end

  add_to_serializer(:topic_view, :topic_alarm_time, include_condition: -> { scope.can_set_topic_alarm? }) do
    object.topic.custom_fields["topic_alarm_time"].to_i
  end

  add_to_serializer(:topic_view, :topic_alarm_description, include_condition: -> { scope.can_set_topic_alarm? }) do
    object.topic.custom_fields["topic_alarm_description"]
  end
end

