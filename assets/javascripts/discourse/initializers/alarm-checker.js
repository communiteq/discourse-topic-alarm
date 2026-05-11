import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { withPluginApi } from "discourse/lib/plugin-api";
import TopicAlarmEditor from "../components/modal/topic-alarm-editor";

export default {
  name: "topic-alarm",

  initialize(container) {
    withPluginApi("1.2.0", (api) => {
      const currentUser = api.getCurrentUser();

      api.registerTopicFooterButton({
        id: "topic-alarm",
        icon() {
          return this.topic.topic_alarm_time > 0 ? "clock" : "far-clock";
        },
        priority: 240,
        label() {
          if (this.topic.topic_alarm_time > 0) {
            return "topic_alarm.edit_topic_alarm_button.label";
          } else {
            if (this.topic.topic_alarm_user_time > 0) {
              return "topic_alarm.clear_topic_alarm_button.label";
            } else {
              return "topic_alarm.set_topic_alarm_button.label";
            }
          }
        },
        title() {
          if (this.topic.topic_alarm_time > 0) {
            return "topic_alarm.edit_topic_alarm_button.title";
          } else {
            if (this.topic.topic_alarm_user_time > 0) {
              return "topic_alarm.clear_topic_alarm_button.title";
            } else {
              return "topic_alarm.set_topic_alarm_button.title";
            }
          }
        },
        action() {
          if (
            this.topic.topic_alarm_time > 0 ||
            !this.topic.topic_alarm_user_time > 0
          ) {
            const modal = container.lookup("service:modal");
            modal.show(TopicAlarmEditor, {
              model: {
                topic: this.topic,
                existing_alarm: this.topic.topic_alarm_time > 0,
              },
            });
          } else {
            ajax("/topic-alarm/destroy", {
              type: "DELETE",
              data: {
                topic_id: this.topic.id,
              },
            })
              .then(() => {
                this.topic.set("topic_alarm_time", null);
                this.topic.set("topic_alarm_user_time", null);
                this.topic.set("topic_alarm_description", null);
              })
              .catch((error) => popupAjaxError(error));
          }
        },
        dropdown() {
          return false; // if it is in dropdown, keyboard input does not work
        },
        classNames: ["topic-alarm"],
        dependentKeys: ["topic.topic_alarm_time"],
        displayed() {
          return currentUser?.can_set_topic_alarm;
        },
      });
    });
  },
};
