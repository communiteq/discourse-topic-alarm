import { tracked } from "@glimmer/tracking";
import Component, { Input } from "@ember/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import ItsATrap from "@discourse/itsatrap";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import TimeShortcutPicker from "discourse/components/time-shortcut-picker";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { formattedReminderTime } from "discourse/lib/bookmark";
import {
  TIME_SHORTCUT_TYPES,
  timeShortcuts,
} from "discourse/lib/time-shortcut";
import { i18n } from "discourse-i18n";

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
    return [shortcuts.tomorrow(), shortcuts.monday(), shortcuts.nextMonth()];
  }

  @action
  onTimeSelected(type, time) {
    let ts = time.unix();
    this.model.topic.set("topic_alarm_time", ts);
    this.model.topic.set("topic_alarm_user_time", ts);
  }

  get hiddenTimeShortcutOptions() {
    return [TIME_SHORTCUT_TYPES.NONE];
  }

  get customTimeShortcutLabels() {
    const labels = {};
    return labels;
  }

  get existingReminderAtFormatted() {
    return formattedReminderTime(
      this.model.topic.get("topic_alarm_time") * 1000,
      this.userTimezone
    );
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
    const act = this.hasExistingTopicAlarm ? "edit" : "create";
    return i18n(`topic_alarm.alarm_editor.${act}`);
  }

  get buttonTitle() {
    const act = this.hasExistingTopicAlarm ? "edit" : "set";
    return `topic_alarm.${act}_topic_alarm_button.label`;
  }

@action
  setTopicAlarm() {
    ajax("/topic-alarm/set", {
      type: "POST",
      data: {
        topic_id: this.model.topic.id,
        topic_alarm_time: this.model.topic.get("topic_alarm_time"),
        topic_alarm_description: this.model.topic.get(
          "topic_alarm_description"
        ),
      },
    })
      .then(() => {})
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
      },
    })
      .then(() => {
        this.model.topic.set("topic_alarm_time", null);
        this.model.topic.set("topic_alarm_user_time", null);
        this.model.topic.set("topic_alarm_description", null);
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.closeModal();
      });
  }

  <template>
    <DModal
      @title={{this.modalTitle}}
      @closeModal={{@closeModal}}
      class="topic-alarm-editor"
    >
      <:body>
        <Input
          type="text"
          @value={{this.model.topic.topic_alarm_description}}
          placeholder={{i18n "topic_alarm.description_placeholder"}}
        />
        {{#if this.hasTopicAlarm}}
          <div class="alert alert-info existing-reminder-at-alert">
            {{icon "far-clock"}}
            <span>{{i18n
                "topic_alarm.existing_alarm"
                at_date_time=this.existingReminderAtFormatted
              }}</span>
          </div>
        {{/if}}
        <TimeShortcutPicker
          @timeShortcuts={{this.timeOptions}}
          @prefilledDatetime={{this.prefilledDatetime}}
          @onTimeSelected={{this.onTimeSelected}}
          @hiddenOptions={{this.hiddenTimeShortcutOptions}}
          @customLabels={{this.customTimeShortcutLabels}}
          @_itsatrap={{this._itsatrap}}
        />
      </:body>
      <:footer>
        <DButton
          @action={{this.setTopicAlarm}}
          class="btn-primary"
          @label={{this.buttonTitle}}
          @disabled={{this.hasNoTopicAlarm}}
        />
        {{#if this.hasExistingTopicAlarm}}
          <DButton
            @action={{this.deleteTopicAlarm}}
            class="btn-danger"
            @label="topic_alarm.delete_topic_alarm_button.label"
          />
        {{/if}}
      </:footer>
    </DModal>
  </template>
}
