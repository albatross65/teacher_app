class Course {
  final String id;
  final String name;
  final List<Topic> topics;

  Course({
    required this.id,
    required this.name,
    required this.topics,
  });

  int get topicCount => topics.length; // Dynamically calculate topic count

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'topics': topics.map((topic) => topic.toMap()).toList(),
      'topicCount': topicCount, // This will always give the current count
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      name: map['name'],
      topics: (map['topics'] as List<dynamic>)
          .map((topicData) => Topic.fromMap(topicData))
          .toList(),
    );
  }
}

class Topic {
  final String id;
  final String name;
  final String url;
  final String text;
  bool isVisible; // Remove final to make it mutable
  bool isCompleted; // Remove final to make it mutable
  final String? gitLink;

  Topic({
    required this.id,
    required this.name,
    required this.url,
    required this.text,
    this.isVisible = true,
    this.isCompleted = false,
    this.gitLink,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'text': text,
      'isVisible': isVisible,
      'isCompleted': isCompleted,
      'gitLink': gitLink,
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      text: map['text'],
      isVisible: map['isVisible'] ?? true,
      isCompleted: map['isCompleted'] ?? false,
      gitLink: map['gitLink'],
    );
  }
}
