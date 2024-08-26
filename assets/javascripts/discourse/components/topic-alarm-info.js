import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { formattedReminderTime } from "discourse/lib/bookmark";
import { bind } from "discourse-common/utils/decorators";

export default class TopicAlarmInfo extends Component {
  @service currentUser;
  @service messageBus;

  @tracked userTimezone;

  constructor() {
    super(...arguments);
    this.userTimezone = this.currentUser.user_option.timezone;
    this.subscribe();
  }

  willDestroy() {
    this.unsubscribe();
  }

  @bind
  subscribe() {
    if (this.currentUser && this.currentUser.can_set_topic_alarm) {
      const channel = `/topic-alarm/`;
      this.messageBus.subscribe(channel, this._processMessage);
    }
  }

  @bind
  unsubscribe() {
    if (this.currentUser && this.currentUser.can_set_topic_alarm) {
      const channel = `/topic-alarm/`;
      this.messageBus.unsubscribe(channel, this._processMessage);
    }
  }

  @bind
  _processMessage(data) {
    if (data.topic_id == this.args.topic.get("id")) {
      this.args.topic.set("topic_alarm_time", data.topic_alarm_time);
      this.args.topic.set("topic_alarm_description", data.topic_alarm_description);
    }
  }

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

