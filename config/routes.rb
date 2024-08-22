DiscourseTopicAlarm::Engine.routes.draw do
  post "set" => "topic_alarm#set"
  delete "destroy" => "topic_alarm#destroy"
end

Discourse::Application.routes.append do
  mount ::DiscourseTopicAlarm::Engine, at: "/topic-alarm"
end
