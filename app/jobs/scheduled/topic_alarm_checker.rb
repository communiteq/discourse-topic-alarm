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
          topic = Topic.find(custom_field.topic_id)
          notify_groups(topic) if topic

          # Clear the alarm after notifying
          topic.custom_fields["topic_alarm_time"] = nil
          topic.custom_fields["topic_alarm_description"] = nil
          topic.save_custom_fields
        end
    end

    private

    def notify_groups(topic)
      return unless SiteSetting.topic_alarm_groups.present?

      allowed_group_ids = SiteSetting.topic_alarm_groups.split('|').map(&:to_i)
      notified_users = Set.new

      Group.where(id: allowed_group_ids).each do |group|
        group.users.each do |user|
          next if notified_users.include?(user.id)

          Notification.create!(
            user_id: user.id,
            notification_type: Notification.types[:bookmark_reminder],
            topic_id: topic.id,
            post_number: 1,
            data: {
              title: topic.title,
              message: topic.custom_fields["topic_alarm_description"]
            }.to_json
          )
          notified_users.add(user.id)
        end
      end
    end
  end
end
