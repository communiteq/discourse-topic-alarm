import Component from "@ember/component";
import { classNames } from "@ember-decorators/component";
import TopicAlarmInfo from "../../components/topic-alarm-info";

@classNames("topic-above-footer-buttons-outlet", "topic-alarm-conn")
export default class TopicAlarmConnConnector extends Component {
  <template><TopicAlarmInfo @topic={{@outletArgs.model}} /></template>
}
