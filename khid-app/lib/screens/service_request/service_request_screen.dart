// lib/screens/service_request/service_request_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_request_form_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/error_handler.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/form_bottom_nav.dart';
import 'widgets/my_requests_panel.dart';
import 'widgets/screen_header.dart';
import 'widgets/step_confirm.dart';
import 'widgets/step_describe.dart';
import 'widgets/step_service_type.dart';

// ============================================================================
// SERVICE REQUEST SCREEN
// Root screen: owns TabController + step index.
// Business rule canAdvanceStep() lives in ServiceRequestFormState — not here.
//

class ServiceRequestScreen extends ConsumerStatefulWidget {
  final bool isEmergency;

  const ServiceRequestScreen({super.key, this.isEmergency = false});

  @override
  ConsumerState<ServiceRequestScreen> createState() =>
      _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends ConsumerState<ServiceRequestScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentStep = 0;
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Color _accent(bool isDark) {
    if (widget.isEmergency) return AppTheme.signOutRed;
    return isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final accent   = _accent(isDark);
    final state    = ref.watch(
        serviceRequestFormControllerProvider(widget.isEmergency));
    final notifier = ref.read(
        serviceRequestFormControllerProvider(widget.isEmergency).notifier);

    ref.listen<ServiceRequestFormState>(
      serviceRequestFormControllerProvider(widget.isEmergency),
      (prev, next) {
        if (next.submitStatus == SubmitStatus.error &&
            prev?.submitStatus != SubmitStatus.error) {
          ErrorHandler.showErrorSnackBar(
              context, context.tr('request_form.submit_error'));
          notifier.resetError();
        }
        if (next.submitStatus == SubmitStatus.success &&
            prev?.submitStatus != SubmitStatus.success) {
          setState(() => _currentStep = 0);
          _tabController.animateTo(1);
          // Fresh form for the next request — the previous serviceType,
          // description, media and priority must not linger in the wizard.
          _descriptionCtrl.clear();
          ref.invalidate(
              serviceRequestFormControllerProvider(widget.isEmergency));
        }
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      // System back mirrors the in-form back button: on step 2/3 of the
      // wizard it steps back instead of discarding the whole form; on step 0
      // (or the my-requests tab) it leaves the screen normally.
      child: PopScope(
        canPop: _currentStep == 0 || _tabController.index != 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _currentStep--);
        },
        child: Scaffold(
          body: Column(
            children: [
              ServiceRequestScreenHeader(
                isDark:        isDark,
                accent:        accent,
                isEmergency:   widget.isEmergency,
                currentStep:   _currentStep,
                tabController: _tabController,
                showStepper:   _tabController.index == 0,
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    IndexedStack(
                      index: _currentStep,
                      children: [
                        StepServiceType(
                          selected:          state.serviceType,
                          scheduledDate:     state.scheduledDate,
                          scheduledTime:     state.scheduledTime,
                          isDark:            isDark,
                          accentColor:       accent,
                          onServiceSelected: notifier.selectServiceType,
                          onAsap:            notifier.setScheduleAsap,
                          onTodayEvening:    notifier.setScheduleTodayEvening,
                          onTomorrow:        notifier.setScheduleTomorrow,
                          onDateChanged:     notifier.setScheduledDate,
                          onTimeChanged:     notifier.setScheduledTime,
                        ),
                        StepDescribe(
                          descriptionController: _descriptionCtrl,
                          mediaFiles:            state.mediaFiles,
                          isDark:                isDark,
                          accentColor:           accent,
                          charCount:             state.description.length,
                          serviceType:           state.serviceType,
                          onDescriptionChanged:  notifier.setDescription,
                          onPickGallery:         notifier.pickFromGallery,
                          onPickCamera:          notifier.pickFromCamera,
                          onPickVideo:           notifier.pickVideo,
                          onRemoveMedia:         notifier.removeMedia,
                        ),
                        StepConfirm(
                          latitude:             state.latitude,
                          longitude:            state.longitude,
                          address:              state.address,
                          locationStatus:       state.locationStatus,
                          isGeocodingAddress:   state.isGeocodingAddress,
                          priority:             state.priority,
                          serviceType:          state.serviceType,
                          scheduledDate:        state.scheduledDate,
                          scheduledTime:        state.scheduledTime,
                          mediaCount:           state.mediaCount,
                          isDark:               isDark,
                          accentColor:          accent,
                          onRetryLocation:      notifier.retryLocation,
                          onAddressChanged:     notifier.setAddress,
                          onGeocodeAddress:     () =>
                              notifier.geocodeManualAddress(state.address),
                          onPrioritySelected:   notifier.setPriority,
                          onMapLocationChanged: notifier.setMapPickedLocation,
                        ),
                      ],
                    ),

                    MyRequestsPanel(
                      isDark:       isDark,
                      accentColor:  accent,
                      onNewRequest: () => _tabController.animateTo(0),
                    ),
                  ],
                ),
              ),

              AnimatedSize(
                duration: AppConstants.animDurationMicro,
                curve:    Curves.easeOut,
                child: _tabController.index == 0
                    ? FormBottomNav(
                        isDark:      isDark,
                        accent:      accent,
                        currentStep: _currentStep,
                        state:       state,
                        onBack: _currentStep > 0
                            ? () => setState(() => _currentStep--)
                            : null,
                        onNext: state.canAdvanceStep(_currentStep)
                            ? () {
                                if (_currentStep < 2) {
                                  setState(() => _currentStep++);
                                } else {
                                  notifier.submit();
                                }
                              }
                            : null,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
