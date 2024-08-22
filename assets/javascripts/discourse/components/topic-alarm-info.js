import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { formattedReminderTime } from "discourse/lib/bookmark";

export default class TopicAlarmInfo extends Component {
  @service currentUser;
  @tracked userTimezone = this.currentUser.user_option.timezone;

  get hasTopicAlarm() {
    return this.args.topic.get("topic_alarm_time") > 0;
  }

  get topicAlarmDescription() {
    return this.args.topic.get("topic_alarm_description");
  }

  get existingAlarmAtFormatted() {
    return formattedReminderTime(this.args.topic.get("topic_alarm_time") * 1000, this.userTimezone);
  }
}

