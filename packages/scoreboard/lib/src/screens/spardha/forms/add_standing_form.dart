import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scoreboard/src/globals/constants.dart';
import 'package:scoreboard/src/globals/enums.dart';
import 'package:scoreboard/src/models/standing_model.dart';
import 'package:scoreboard/src/screens/home.dart';
import 'package:scoreboard/src/services/api.dart';
import 'package:scoreboard/src/stores/common_store.dart';
import 'package:scoreboard/src/stores/static_store.dart';
import 'package:scoreboard/src/widgets/add_event/drop_down.dart';
import 'package:scoreboard/src/widgets/add_result/hostel_dropdown.dart';
import '../../../functions/snackbar.dart';
import '../../../functions/validator.dart';
import '../../../globals/colors.dart';
import '../../../stores/standing_form_store.dart';
import '../../../widgets/add_result/custom_text_field.dart';
import '../../../widgets/add_result/fields_mandatory.dart';
import '../../../functions/position.dart';

class AddStanding extends StatefulWidget {
  final StandingModel? standings;

  const AddStanding({super.key, this.standings});

  @override
  State<AddStanding> createState() => _AddStandingState();
}

class _AddStandingState extends State<AddStanding> {

  final StandingFormStore standingFormStore = StandingFormStore();

  @override
  void initState() {
    super.initState();
    if(widget.standings != null)
      {
        standingFormStore.setPreData(widget.standings!);
      }
  }
  final key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {

    var commStore = context.read<CommonStore>();

    return Scaffold(
        backgroundColor: Themes.theme.backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Themes.theme.backgroundColor,
          shape: Border(
            bottom: BorderSide(
              color: Themes.theme.dividerColor,
              width: 1,
            ),
          ),
          centerTitle: true,
          title: Text(
            widget.standings == null ? 'Add Standings' : 'Edit Standings',
            style: Themes.theme.textTheme.headline2,
          ),
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.close,
              color: Themes.theme.primaryColor,
            ),
            splashColor: const Color.fromRGBO(118, 172, 255, 0.9),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (!key.currentState!.validate()) {
                  return;
                }
                try {
                  if (widget.standings == null) {
                    await APIService(context).postSpardhaStanding({
                      "category": standingFormStore.category!.categoryName,
                      'event': standingFormStore.event,
                      'standings': List<Map>.from(
                          standingFormStore.standing!.map((e) => e.toJson()))
                    });
                    showSnackBar(context, "Standing added");
                  } else {
                    widget.standings!.category=standingFormStore.category!.categoryName;
                    widget.standings!.event=standingFormStore.event;
                    widget.standings!.standings=standingFormStore.standing;
                    await APIService(context).updateSpardhaStanding(widget.standings!);
                    showSnackBar(context, "Standing updated");
                  }
                  commStore.competition=Competitions.gc; // show gc standings page on main screen
                  Navigator.pushNamedAndRemoveUntil(context, ScoreBoardHome.id, (route) => false);
                }
                on DioError catch(err)
                {
                  print(err.toString());
                  showErrorSnackBar(context, err);
                }
              },
              child: Text(
                'Next',
                style: Themes.theme.textTheme.headline3,
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            width: double.infinity,
            child: Form(
              key: key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldsMandatory(),
                  const SizedBox(
                    height: 28,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 30,
                        child: CustomDropDown(
                            items: StaticStore.spardhaEvents,
                            hintText: 'Event',
                            value: standingFormStore.event,
                            onChanged: (value) {
                              setState(() {
                                standingFormStore.event = value;
                              });
                            },
                            validator: validateField),
                      ),
                      const Spacer(
                        flex: 10,
                      ),
                      Expanded(
                        flex: 30,
                        child: CustomDropDown(
                            items: eventCategories,
                            hintText: 'Category',
                            value: standingFormStore.category?.categoryName,
                            onChanged: (value) {
                              setState(() {
                                standingFormStore.clearStandings();
                                if (value == "Men") {
                                  standingFormStore.category = Category.men;
                                } else if (value == 'Women') {
                                  standingFormStore.category = Category.women;
                                } else {
                                  standingFormStore.category = Category.menandwomen;
                                }
                              });
                            },
                            validator: validateField),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  for(int index=1;index<=standingFormStore.standing.length;index++)
                  Column(
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                        Row(
                          children: [
                            Text(
                              getPosition(index - 1),
                              style: Themes.theme.textTheme.bodyText2,
                            ),
                            const Spacer(),
                          ],
                        ),
                      const SizedBox(
                        height: 20,
                      ),
                        Row(
                          children: [
                            Expanded(
                              flex: 50,
                              child: HostelDropDown(
                                validator: validateField,
                                value:
                                standingFormStore.standing[index - 1].hostelName,
                                onChanged: (hostel) => standingFormStore
                                    .standing[index - 1]
                                    .hostelName = hostel,
                                hostels: getHostel(standingFormStore.category),
                              ),
                            ),
                              const Spacer(
                                flex: 10,
                              ),
                            Expanded(
                              flex: 35,
                              child: CustomTextField(
                                isNecessary: true,
                                inputType: TextInputType.number,
                                hintText: 'Points',
                                validator: validateField,
                                onChanged: (value) {
                                  print(value);
                                  standingFormStore.standing[index - 1].points =
                                      int.parse(value);
                                  // print(standingFormStore.standing![index - 1].points);
                                },
                                value: standingFormStore.standing[index - 1].points
                                    .toString(),
                              ),
                            )
                          ],
                        ),
                    ],
                  ),
                  TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        setState(() {
                          standingFormStore.addNewPosition();
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.add,
                            color: Themes.theme.primaryColor,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Add Position',
                            style: Themes.theme.textTheme.headline3,
                          )
                        ],
                      ))
                ],
              ),
            ),
          ),
        ));
  }
}
