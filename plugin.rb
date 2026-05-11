# name: discourse-topic-alarm
# about: Allows users in specified groups to set an alarm on a topic
# version: 2026.1.2
# authors: Communiteq

enabled_site_setting :topic_alarm_enabled

register_asset "stylesheets/topic_alarm.scss"
register_asset "stylesheets/topic_alarm_mobile.scss", :mobile

register_svg_icon("clock")
register_svg_icon("far-clock")

require_relative 'lib/discourse_topic_alarm/engine'

after_initialize do
  require_relative "app/controllers/discourse_topic_alarm/topic_alarm_controller"
  require_relative "app/jobs/scheduled/topic_alarm_checker"

  reloadable_patch do |plugin|
    add_to_class(:user, :can_set_topic_alarm?) do
      return false unless SiteSetting.topic_alarm_groups.present?
      allowed_group_ids = SiteSetting.topic_alarm_groups.split('|').map(&:to_i)
      (group_ids & allowed_group_ids).any?
    end

    add_to_class(:topic, :publish_alarm) do
      allowed_group_ids = SiteSetting.topic_alarm_groups.split('|').map(&:to_i)
      user_ids = User.joins(:groups).where(groups: { id: allowed_group_ids }).distinct.pluck(:id)
      MessageBus.publish("/topic-alarm/", {
          topic_id: id,
          topic_alarm_time: custom_fields["topic_alarm_time"],
          topic_alarm_user_time: custom_fields["topic_alarm_user_time"],
          topic_alarm_description: custom_fields["topic_alarm_description"]
        },
        user_ids: user_ids
      )
    end

    add_to_class(:guardian, :can_set_topic_alarm?) do
      user && user.can_set_topic_alarm?
    end
  end

  add_to_serializer(:current_user, :can_set_topic_alarm) do
    object.can_set_topic_alarm?
  end

  add_to_serializer(:topic_view, :topic_alarm_time, include_condition: -> { scope.can_set_topic_alarm? }) do
    object.topic.custom_fields["topic_alarm_time"].to_i
  end

  add_to_serializer(:topic_view, :topic_alarm_user_time, include_condition: -> { scope.can_set_topic_alarm? }) do
    object.topic.custom_fields["topic_alarm_user_time"].to_i
  end

  add_to_serializer(:topic_view, :topic_alarm_description, include_condition: -> { scope.can_set_topic_alarm? }) do
    object.topic.custom_fields["topic_alarm_description"]
  end
end

