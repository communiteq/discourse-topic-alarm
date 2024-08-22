import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import TopicAlarmEditor from "../components/modal/topic-alarm-editor";

export default {
  name: "topic-alarm",

  initialize(container) {
    withPluginApi("1.2.0", (api) => {
      const currentUser = api.getCurrentUser();

      api.registerTopicFooterButton({
        id: "topic-alarm",
        icon() {
          return this.topic.topic_alarm_time > 0 ? "bell" : "far-bell";
        },
        priority: 240,
        label() {
          return this.topic.topic_alarm_time > 0 ? "topic_alarm.edit_topic_alarm_button.label" : "topic_alarm.set_topic_alarm_button.label"
        },
        title() {
          return this.topic.topic_alarm_time > 0 ? "topic_alarm.edit_topic_alarm_button.title" : "topic_alarm.set_topic_alarm_button.label"
        },
        action() {
          const modal = container.lookup("service:modal");
          modal.show(TopicAlarmEditor, {
            model: {
              topic: this.topic,
              existing_alarm: (this.topic.topic_alarm_time > 0)
            }
          });
        },
        dropdown() {
          return this.site.mobileView;
        },
        classNames: ["topic-alarm"],
        dependentKeys: ["topic.topic_alarm_time"],
        displayed() {
          return currentUser?.can_set_topic_alarm
        },
      });
    });
  }
}

