import 'package:flutter/material.dart';
import 'package:src/widgets/navigation.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image(image: AssetImage("assets/logo.png"), height: 40),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Our Story",
                  style: Theme.of(
                    context,
                  ).typography.black.headlineMedium!.apply(fontWeightDelta: 3),
                ),
                SizedBox(height: 20),
                Text(
                  "The Illini Dads Association is a group of fathers (and father figures) of a University of Illinois student! If you're a first-time U of I parent, you're probably looking for resources to help you with your student's transition to life as an Illini, and that's where the Dads Association can help. We have a lot of experience helping families get acclimated to the University community and student life at Illinois.",
                  style: Theme.of(context).typography.black.bodyMedium,
                ),
                SizedBox(height: 20),
                Text(
                  "So who is the Dads Association?",
                  style: Theme.of(
                    context,
                  ).typography.black.bodyMedium!.apply(fontWeightDelta: 3),
                ),
                SizedBox(height: 5),
                Text(
                  "You are. Every father figure of a U of I student is granted membership in the Association automatically. If you subscribe to our mailing list, you'll receive regular updates on campus activities, hints to help your student, and what the Illini Dads are doing in the campus community.",
                  style: Theme.of(context).typography.black.bodyMedium,
                ),
                SizedBox(height: 20),
                Text(
                  "We Award Scholarships and Grants",
                  style: Theme.of(
                    context,
                  ).typography.black.bodyMedium!.apply(fontWeightDelta: 3),
                ),
                SizedBox(height: 5),
                Text(
                  "Illini Dads is not only an information source: we're a philanthropic organization. We award in excess of \$20,000 per year in grants to student organizations and in student scholarships. We have awarded >\$1M since 1922.",
                  style: Theme.of(context).typography.black.bodyMedium,
                ),
                SizedBox(height: 20),
                Text(
                  "We Organize Dads Weekend",
                  style: Theme.of(
                    context,
                  ).typography.black.bodyMedium!.apply(fontWeightDelta: 3),
                ),
                SizedBox(height: 5),
                Text(
                  "We are the primary sponsor and organizer of Dads Weekend (a tradition for >100 years), which is held in the fall each year on a football weekend. We have events throughout the weekend, including a pregame BBQ, specially priced football, basketball and hockey tickets, a Saturday night concert on campus, a 5k run and a Sunday brunch. Proceeds from these events fund our scholarship and grant programs.",
                  style: Theme.of(context).typography.black.bodyMedium,
                ),
                SizedBox(height: 20),
                Text(
                  "We Anoint a King Dad",
                  style: Theme.of(
                    context,
                  ).typography.black.bodyMedium!.apply(fontWeightDelta: 3),
                ),
                SizedBox(height: 5),
                Text(
                  "During Dads Weekend, we select and honor the King Dad. Students can nominate dads, and our board reviews all the nominations to choose one deserving individual who receives the royal treatment for the entire weekend, including a hotel room at the Union, breakfast with the Chancellor, luxury suite tickets to the football game with recognition on the field and on the Jumbotron during the game, tickets to all our events and swag.",
                  style: Theme.of(context).typography.black.bodyMedium,
                ),
                SizedBox(height: 20),
                Text(
                  "Want to Get Involved?",
                  style: Theme.of(
                    context,
                  ).typography.black.bodyMedium!.apply(fontWeightDelta: 3),
                ),
                SizedBox(height: 5),
                Text(
                  "The Dads Association is also always looking for Board members. Our Board changes as students graduate. If you're looking for a way to get involved with campus life and make a positive impact on the student and university community, please consider volunteering for the Dads Association Board of Directors. Email me your interest at president@illinidads.com.\n\nAgain, welcome to the Illini Dads, and GO ILLINI!\n\nFerdinand Belga\nPresident, Illini Dads Association at the University of Illinois Urbana-Champaign​",
                  style: Theme.of(context).typography.black.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Navigation(selected: 0),
    );
  }
}
