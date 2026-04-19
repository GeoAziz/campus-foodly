import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:form_field_validator/form_field_validator.dart';

import '../../../core/routes.dart';
import '../../../constants.dart';

import '../../../components/buttons/primary_button.dart';
import '../../../data/providers/ui_state_provider.dart';

class OtpForm extends ConsumerStatefulWidget {
  const OtpForm({super.key});

  @override
  ConsumerState<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends ConsumerState<OtpForm> {
  final _formKey = GlobalKey<FormState>();
  final _pin1Controller = TextEditingController();
  final _pin2Controller = TextEditingController();
  final _pin3Controller = TextEditingController();
  final _pin4Controller = TextEditingController();

  FocusNode? _pin1Node;
  FocusNode? _pin2Node;
  FocusNode? _pin3Node;
  FocusNode? _pin4Node;

  @override
  void initState() {
    super.initState();
    _pin1Node = FocusNode();
    _pin2Node = FocusNode();
    _pin3Node = FocusNode();
    _pin4Node = FocusNode();
  }

  @override
  void dispose() {
    _pin1Controller.dispose();
    _pin2Controller.dispose();
    _pin3Controller.dispose();
    _pin4Controller.dispose();
    super.dispose();
    _pin1Node!.dispose();
    _pin2Node!.dispose();
    _pin3Node!.dispose();
    _pin4Node!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: TextFormField(
                  controller: _pin1Controller,
                  onChanged: (value) {
                    if (value.length == 1) _pin2Node!.requestFocus();
                  },
                  validator: RequiredValidator(errorText: '').call,
                  autofocus: true,
                  maxLength: 1,
                  focusNode: _pin1Node,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: otpInputDecoration,
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: TextFormField(
                  controller: _pin2Controller,
                  onChanged: (value) {
                    if (value.length == 1) _pin3Node!.requestFocus();
                  },
                  validator: RequiredValidator(errorText: '').call,
                  maxLength: 1,
                  focusNode: _pin2Node,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: otpInputDecoration,
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: TextFormField(
                  controller: _pin3Controller,
                  onChanged: (value) {
                    if (value.length == 1) _pin4Node!.requestFocus();
                  },
                  validator: RequiredValidator(errorText: '').call,
                  maxLength: 1,
                  focusNode: _pin3Node,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: otpInputDecoration,
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: TextFormField(
                  controller: _pin4Controller,
                  onChanged: (value) {
                    if (value.length == 1) _pin4Node!.unfocus();
                  },
                  validator: RequiredValidator(errorText: '').call,
                  maxLength: 1,
                  focusNode: _pin4Node,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: otpInputDecoration,
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding * 2),
          // Continue Button
          PrimaryButton(
            text: "Continue",
            press: () async {
              if (_formKey.currentState!.validate()) {
                // If all data are correct then save data to out variables
                _formKey.currentState!.save();
                final code = [
                  _pin1Controller.text,
                  _pin2Controller.text,
                  _pin3Controller.text,
                  _pin4Controller.text,
                ].join();
                final success = await ref
                    .read(phoneLoginControllerProvider.notifier)
                    .verifyCode(code);
                if (!context.mounted) {
                  return;
                }
                if (success) {
                  context.goNamed(AppRoutes.app);
                }
              }
            },
          )
        ],
      ),
    );
  }
}
