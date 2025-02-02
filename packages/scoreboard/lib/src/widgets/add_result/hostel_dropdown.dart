import 'package:flutter/material.dart';
import '../../globals/colors.dart';
import '../../globals/styles.dart';

class HostelDropDown extends StatelessWidget {
  final List<String> hostels;
  final String? Function(String?)? validator;
  final void Function(String?)? onChanged;
  final String? value;

  const HostelDropDown(
      {super.key,
      required this.onChanged,
      required this.value,
      required this.validator,
      required this.hostels});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      menuMaxHeight: 400,
      isExpanded: true,
      validator: validator,
      decoration: InputDecoration(
        errorStyle: basicFontStyle,
        label: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Hostels',
                style: Themes.theme.textTheme.bodyText1,
              ),
              TextSpan(
                text: ' * ',
                style: Themes.theme.textTheme.headline5,
              ),
            ],
          ),
        ),
        labelStyle: Themes.theme.textTheme.bodyText1,
        hintStyle: Themes.theme.textTheme.bodyText1,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Themes.theme.focusColor, width: 1),
          borderRadius: const BorderRadius.all(
            Radius.circular(4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Themes.theme.focusColor, width: 1),
          borderRadius: const BorderRadius.all(
            Radius.circular(4),
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1),
          borderRadius: BorderRadius.all(
            Radius.circular(4),
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1),
          borderRadius: BorderRadius.all(
            Radius.circular(4),
          ),
        ),
      ),
      dropdownColor: Themes.theme.backgroundColor,
      isDense: true,
      icon: const Icon(
        Icons.arrow_drop_down,
        size: 28,
      ),
      elevation: 16,
      style: Themes.theme.textTheme.headline6,
      onChanged: onChanged,
      value: value,
      items: hostels.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
