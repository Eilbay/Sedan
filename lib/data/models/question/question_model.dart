class QuestionModel {
  late int? id;
  late String question;
  late String? name;
  late String? email;
  late String? phoneNumber;

  QuestionModel(
      {this.id,
      this.question = "",
      this.name,
      this.email,
      this.phoneNumber});

  QuestionModel.copyWith(QuestionModel question)
      : this(
            id: question.id,
            question: question.question,
            name: question.name,
            email: question.email,
            phoneNumber: question.phoneNumber);

  QuestionModel.fromJson(Map<String, dynamic> json)
      : id = json["id"] ?? 0,
        question = json["question"],
        name = json["name"] ?? '',
        email = json['email'] ?? '',
        phoneNumber = json['phone_number'] ?? '';

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "question": question,
      "email": email,
      "phone_number": phoneNumber,
    };
  }
}
