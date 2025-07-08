import "package:flutter/material.dart";
import "package:http/http.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:src/services/secure_storage.dart";
import "package:src/widgets/navigation.dart";

class NamePage extends StatefulWidget {
  const NamePage({super.key});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  late int user_id;
  late String token;
  late String name;
  String original = "";
  bool loaded = false;
  String? error;
  TextEditingController controller = TextEditingController();

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

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
          "Change Name",
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
                (original != name)
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
                          error = null;
                        });
                        SecureStorage.writeOne("name", name);
                        await post(
                          Uri.parse(baseUrl + "/change-name/"),
                          headers: {"Authorization": "Token ${token}"},
                          body: {"user_id": user_id.toString(), "name": name},
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
