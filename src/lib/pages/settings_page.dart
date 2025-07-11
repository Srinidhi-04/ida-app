import "package:flutter/material.dart";
import "package:http/http.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:src/services/secure_storage.dart";
import "package:src/widgets/navigation.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int user_id;
  late String token;
  late String name;
  late int avatar;
  String original = "";
  bool loaded = false;
  String? error;
  TextEditingController controller = TextEditingController();

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  late int selected;

  Widget avatarOption(int option) {
    return GestureDetector(
      onTap:
          () => setState(() {
            selected = option;
          }),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.12,
        height: MediaQuery.of(context).size.width * 0.12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage("assets/avatar_${option}.png"),
            colorFilter:
                (option == selected)
                    ? ColorFilter.mode(Color(0x88000000), BlendMode.darken)
                    : null,
          ),
        ),
      ),
    );
  }

  Future<void> checkLogin() async {
    Map<String, String> info = await SecureStorage.read();
    if (info["last_login"] != null) {
      DateTime date = DateTime.parse(info["last_login"]!);
      if (DateTime.now().subtract(Duration(days: 30)).compareTo(date) >= 0) {
        await SecureStorage.delete();
        await Navigator.popAndPushNamed(context, "/login");
        return;
      }
    }
    if (info["user_id"] == null) {
      await Navigator.popAndPushNamed(context, "/login");
      return;
    }
    setState(() {
      user_id = int.parse(info["user_id"]!);
      token = info["token"]!;
      name = info["name"]!;
      avatar = int.parse(info["avatar"]!);
      selected = avatar;
      loaded = true;
      controller.text = name;
      original = name;
    });
  }

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded)
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.inkDrop(
            color: Theme.of(context).primaryColorLight,
            size: 100,
          ),
        ),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Manage Profile",
          style: Theme.of(context).typography.black.headlineMedium!.apply(
            color: Theme.of(context).primaryColorDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(color: Theme.of(context).primaryColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Change Avatar",
                      style: Theme.of(
                        context,
                      ).typography.black.labelLarge!.apply(
                        color: Theme.of(context).primaryColorDark,
                        fontWeightDelta: 3,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorDark,
                      shape: BoxShape.circle,
                    ),
                    width: 150,
                    height: 150,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Image(
                        image: AssetImage("assets/avatar_${selected}.png"),
                        height: 140,
                        width: 140,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      avatarOption(1),
                      avatarOption(6),
                      avatarOption(2),
                      avatarOption(7),
                      avatarOption(3),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      avatarOption(8),
                      avatarOption(4),
                      avatarOption(9),
                      avatarOption(5),
                      avatarOption(10),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Change Name",
                      style: Theme.of(
                        context,
                      ).typography.black.labelLarge!.apply(
                        color: Theme.of(context).primaryColorDark,
                        fontWeightDelta: 3,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                  child: TextFormField(
                    controller: controller,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      hintText: "Name",
                      errorText: error,
                    ),
                    cursorColor: Theme.of(context).primaryColor,
                    onChanged:
                        (value) => setState(() {
                          name = value;
                        }),
                  ),
                ),
                (original != name || avatar != selected)
                    ? TextButton(
                      onPressed: () async {
                        if (name.isEmpty) {
                          setState(() {
                            error = "Name cannot be empty";
                          });
                          return;
                        }

                        if (RegExp(r"[^a-zA-Z ]").hasMatch(name)) {
                          setState(() {
                            error = "Invalid name";
                          });
                          return;
                        }

                        setState(() {
                          original = name;
                          avatar = selected;
                          error = null;
                        });
                        SecureStorage.writeMany({
                          "name": name,
                          "avatar": selected.toString(),
                        });
                        await post(
                          Uri.parse(baseUrl + "/edit-profile/"),
                          headers: {"Authorization": "Bearer ${token}"},
                          body: {
                            "user_id": user_id.toString(),
                            "name": name,
                            "avatar": selected.toString(),
                          },
                        );
                      },
                      child: Text(
                        "Save",
                        style: Theme.of(context).typography.white.labelLarge!
                            .apply(fontSizeDelta: 2, fontWeightDelta: 3),
                      ),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          Theme.of(context).primaryColor,
                        ),
                        fixedSize: WidgetStatePropertyAll(
                          Size(0.6 * MediaQuery.of(context).size.width, 50),
                        ),
                        elevation: WidgetStatePropertyAll(10),
                      ),
                    )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Navigation(selected: 4),
    );
  }
}
