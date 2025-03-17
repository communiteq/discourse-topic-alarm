# app/jobs/scheduled/alarm_checker.rb
module Jobs
  class TopicAlarmChecker < ::Jobs::Scheduled
    every 1.minute

    def execute(args)
      return unless SiteSetting.topic_alarm_enabled?

      TopicCustomField
        .where(name: "topic_alarm_time")
        .where("value::int <= ?", Time.now.to_i)
        .find_each do |custom_field|
          topic = Topic.find_by(id: custom_field.topic_id)
          if topic
            notify_groups(topic)

            # Clear the alarm after notifying
            topic.custom_fields["topic_alarm_time"] = nil
            topic.save_custom_fields

            topic.publish_alarm
          end
        end
    end

    private

    def notify_groups(topic)
      return unless SiteSetting.topic_alarm_groups.present?

      allowed_group_ids = SiteSetting.topic_alarm_groups.split('|').map(&:to_i)
      user_ids = User.joins(:groups).where(groups: { id: allowed_group_ids }).distinct.pluck(:id)
      user_ids.each do |user_id|
          Notification.create!(
            user_id: user_id,
            notification_type: Notification.types[:bookmark_reminder],
            topic_id: topic.id,
            post_number: 1,
            data: {
              title: topic.title,
              message: topic.custom_fields["topic_alarm_description"]
            }.to_json
          )
      end
    end
  end
end
