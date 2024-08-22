# app/controllers/topic_alarm_controller.rb
module DiscourseTopicAlarm
  class TopicAlarmController < ::ApplicationController
    before_action :ensure_logged_in

    def set
      raise Discourse::InvalidAccess unless current_user.can_set_topic_alarm?

      topic = Topic.find(params[:topic_id])
      topic.custom_fields["topic_alarm_time"] = params[:topic_alarm_time].to_i
      topic.custom_fields["topic_alarm_description"] = params[:topic_alarm_description]
      topic.save_custom_fields

      render json: success_json
    end

    def destroy
      raise Discourse::InvalidAccess unless current_user.can_set_topic_alarm?

      topic = Topic.find(params[:topic_id])
      topic.custom_fields["topic_alarm_time"] = nil
      topic.custom_fields["topic_alarm_description"] = nil
      topic.save_custom_fields

      render json: success_json
    end
  end
end
