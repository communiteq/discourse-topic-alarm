import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { action, get } from "@ember/object";
import Component from "@ember/component";
import { tracked } from "@glimmer/tracking";
import ItsATrap from "@discourse/itsatrap";
import { formattedReminderTime } from "discourse/lib/bookmark";
import {
  timeShortcuts,
  TIME_SHORTCUT_TYPES,
} from "discourse/lib/time-shortcut";
import I18n from "discourse-i18n";
import { inject as service } from "@ember/service";

export default class TopicAlarmEditor extends Component {
  @service currentUser;
  @tracked prefilledDatetime = null;
  @tracked userTimezone = this.currentUser.user_option.timezone;

  _itsatrap = new ItsATrap();

  init() {
    super.init(...arguments);
  }

  /*** date/time picker ***/

  get timeOptions() {
    const shortcuts = timeShortcuts(this.currentUser.user_option.timezone);
    return [
      shortcuts.tomorrow(),
      shortcuts.monday(),
      shortcuts.nextMonth(),
    ];
  }

  @action
  onTimeSelected(type, time) {
    this.model.topic.set("topic_alarm_time",  time.unix());
  }

  get hiddenTimeShortcutOptions() {
    return [TIME_SHORTCUT_TYPES.NONE];
  }

  get customTimeShortcutLabels() {
    const labels = {};
    return labels;
  }

  get existingReminderAtFormatted() {
    return formattedReminderTime(this.model.topic.get("topic_alarm_time") * 1000, this.userTimezone);
  }

  /*** other functionality */

  get hasTopicAlarm() {
    return this.model.topic.get("topic_alarm_time") > 0;
  }

  get hasExistingTopicAlarm() {
    return this.model.existing_alarm;
  }

  get hasNoTopicAlarm() {
    return !this.hasTopicAlarm;
  }

  get modalTitle() {
    const action = this.hasExistingTopicAlarm ? "edit" : "create";
    return I18n.t(`topic_alarm.alarm_editor.${action}`);
  }

  @action
  setTopicAlarm() {
    ajax("/topic-alarm/set", {
      type: "POST",
      data: {
        topic_id: this.model.topic.id,
        topic_alarm_time: this.model.topic.get("topic_alarm_time"),
        topic_alarm_description: this.model.topic.get("topic_alarm_description")
      }
    })
    .then(() => {
    })
    .catch(popupAjaxError)
    .finally(() => {
      this.closeModal();
    });
  }

  @action
  deleteTopicAlarm() {
    ajax("/topic-alarm/destroy", {
      type: "DELETE",
      data: {
        topic_id: this.model.topic.id,
      }
    })
    .then(() => {
      this.model.topic.set("topic_alarm_time", null);
      this.model.topic.set("topic_alarm_description", null);
    })
    .catch(popupAjaxError)
    .finally(() => {
      this.closeModal();
    });
  }
}
