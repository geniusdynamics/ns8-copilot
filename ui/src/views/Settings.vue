<!--
  Copyright (C) 2022 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="configureModule">
            <NsTextInput
              :label="$t('settings.copilot_fqdn')"
              :helper-text="$t('settings.copilot_fqdn_helper')"
              placeholder="copilot.example.org"
              v-model.trim="host"
              class="mg-bottom"
              :invalid-message="$t(error.host)"
              :disabled="stillLoading"
              ref="host"
            />
            <NsToggle
              value="letsEncrypt"
              :label="$t('settings.lets_encrypt')"
              v-model="isLetsEncryptEnabled"
              :disabled="stillLoading"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
            <NsToggle
              value="httpToHttps"
              :label="$t('settings.http_to_https')"
              v-model="isHttpToHttpsEnabled"
              :disabled="stillLoading"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
            <!-- CoPilot settings, see https://github.com/socfortress/CoPilot/blob/main/.env.example -->
            <cv-accordion ref="accordion" class="maxwidth mg-bottom">
              <cv-accordion-item :open="toggleAccordion[0]">
                <template slot="title">{{
                  $t("settings.section_security")
                }}</template>
                <template slot="content">
                  <NsTextInput
                    :label="$t('settings.access_token_expire_minutes')"
                    :helper-text="
                      $t('settings.access_token_expire_minutes_helper')
                    "
                    v-model.trim="accessTokenExpireMinutes"
                    :invalid-message="error.access_token_expire_minutes"
                    :disabled="stillLoading"
                    ref="access_token_expire_minutes"
                    type="number"
                    class="mg-bottom"
                  />
                  <NsTextInput
                    :label="$t('settings.audit_log_retention_days')"
                    :helper-text="
                      $t('settings.audit_log_retention_days_helper')
                    "
                    v-model.trim="auditLogRetentionDays"
                    :invalid-message="error.audit_log_retention_days"
                    :disabled="stillLoading"
                    ref="audit_log_retention_days"
                    type="number"
                    class="mg-bottom"
                  />
                </template>
              </cv-accordion-item>
              <cv-accordion-item :open="toggleAccordion[1]">
                <template slot="title">{{
                  $t("settings.section_alerts")
                }}</template>
                <template slot="content">
                  <NsComboBox
                    v-model="defaultAlertSeverity"
                    :title="$t('settings.default_alert_severity')"
                    :label="$t('settings.default_alert_severity')"
                    :helper-text="$t('settings.default_alert_severity_helper')"
                    :options="severityOptions"
                    :invalid-message="error.default_alert_severity"
                    :disabled="stillLoading"
                    ref="default_alert_severity"
                    class="mg-bottom"
                  />
                  <NsToggle
                    value="announcementsEnabled"
                    :label="$t('settings.announcements_enabled')"
                    v-model="announcementsEnabled"
                    :disabled="stillLoading"
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </NsToggle>
                  <p class="helper mg-bottom">
                    {{ $t("settings.announcements_enabled_helper") }}
                  </p>
                  <NsToggle
                    value="talonReleaseCheckEnabled"
                    :label="$t('settings.talon_release_check_enabled')"
                    v-model="talonReleaseCheckEnabled"
                    :disabled="stillLoading"
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </NsToggle>
                  <p class="helper mg-bottom">
                    {{ $t("settings.talon_release_check_enabled_helper") }}
                  </p>
                </template>
              </cv-accordion-item>
              <cv-accordion-item :open="toggleAccordion[2]">
                <template slot="title">{{
                  $t("settings.section_mail")
                }}</template>
                <template slot="content">
                  <NsInlineNotification
                    :kind="mailEnabled ? 'info' : 'warning'"
                    :title="
                      $t(mailEnabled ? 'settings.mail_on' : 'settings.mail_off')
                    "
                    :description="
                      $t(
                        mailEnabled
                          ? 'settings.mail_on_description'
                          : 'settings.mail_off_description'
                      )
                    "
                    :showCloseButton="false"
                  />
                  <NsTextInput
                    :label="$t('settings.mail_from')"
                    :helper-text="$t('settings.mail_from_helper')"
                    :placeholder="mailFromPlaceholder"
                    v-model.trim="mailFrom"
                    :invalid-message="error.mail_from"
                    :disabled="stillLoading"
                    ref="mail_from"
                    class="mg-bottom"
                  />
                </template>
              </cv-accordion-item>
            </cv-accordion>
            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="stillLoading"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";

const SECTIONS = [
  ["access_token_expire_minutes", "audit_log_retention_days"],
  [
    "default_alert_severity",
    "announcements_enabled",
    "talon_release_check_enabled",
  ],
  ["mail_from"],
];

export default {
  name: "Settings",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
  ],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      urlCheckInterval: null,
      host: "",
      isLetsEncryptEnabled: false,
      isHttpToHttpsEnabled: true,
      toggleAccordion: [true, false, false],
      accessTokenExpireMinutes: "1440",
      auditLogRetentionDays: "90",
      defaultAlertSeverity: "High",
      announcementsEnabled: true,
      talonReleaseCheckEnabled: true,
      mailEnabled: false,
      mailFrom: "",
      loading: {
        getConfiguration: false,
        configureModule: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        host: "",
        lets_encrypt: "",
        http2https: "",
        access_token_expire_minutes: "",
        audit_log_retention_days: "",
        default_alert_severity: "",
        announcements_enabled: "",
        talon_release_check_enabled: "",
        mail_from: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    stillLoading() {
      return this.loading.getConfiguration || this.loading.configureModule;
    },
    severityOptions() {
      return ["Informational", "Low", "Medium", "High", "Critical"].map(
        (severity) => ({
          name: severity,
          label: this.$t("settings.severity_" + severity.toLowerCase()),
          value: severity,
        })
      );
    },
    mailFromPlaceholder() {
      return `noreply@${this.host || "copilot.example.org"}`;
    },
  },
  created() {
    this.getConfiguration();
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  methods: {
    openSectionOf(param) {
      const index = SECTIONS.findIndex((fields) => fields.includes(param));
      if (index >= 0) {
        this.toggleAccordion = SECTIONS.map((_, i) => i === index);
      }
    },
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getConfigurationAborted
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getConfigurationCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      const config = taskResult.output;
      this.host = config.host;
      this.isLetsEncryptEnabled = config.lets_encrypt;
      this.isHttpToHttpsEnabled = config.http2https;
      this.accessTokenExpireMinutes = String(
        config.access_token_expire_minutes
      );
      this.auditLogRetentionDays = String(config.audit_log_retention_days);
      this.defaultAlertSeverity = config.default_alert_severity;
      this.announcementsEnabled = config.announcements_enabled;
      this.talonReleaseCheckEnabled = config.talon_release_check_enabled;
      this.mailEnabled = config.mail_enabled;
      this.mailFrom = config.mail_from;

      this.loading.getConfiguration = false;
      this.focusElement("host");
    },
    isIntegerBetween(value, min, max) {
      const number = Number(value);
      return (
        value !== "" &&
        Number.isInteger(number) &&
        number >= min &&
        number <= max
      );
    },
    validateConfigureModule() {
      this.clearErrors(this);

      let isValidationOk = true;
      const fail = (param, message) => {
        this.error[param] = message;
        if (isValidationOk) {
          this.openSectionOf(param);
          this.focusElement(param);
        }
        isValidationOk = false;
      };

      if (!this.host) {
        fail("host", "common.required");
      }
      if (!this.isIntegerBetween(this.accessTokenExpireMinutes, 5, 525600)) {
        fail(
          "access_token_expire_minutes",
          this.$t("settings.access_token_expire_minutes_invalid")
        );
      }
      if (!this.isIntegerBetween(this.auditLogRetentionDays, 0, 36500)) {
        fail(
          "audit_log_retention_days",
          this.$t("settings.audit_log_retention_days_invalid")
        );
      }
      if (!this.defaultAlertSeverity) {
        fail("default_alert_severity", this.$t("common.required"));
      }
      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusAlreadySet = false;

      for (const validationError of validationErrors) {
        const param = validationError.parameter;
        // set i18n error message
        this.error[param] = this.$t("settings." + validationError.error);
        this.openSectionOf(param);

        if (!focusAlreadySet) {
          this.focusElement(param);
          focusAlreadySet = true;
        }
      }
    },
    async configureModule() {
      const isValidationOk = this.validateConfigureModule();
      if (!isValidationOk) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.configureModuleAborted
      );

      // register to task validation
      this.core.$root.$once(
        `${taskAction}-validation-failed-${eventId}`,
        this.configureModuleValidationFailed
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.configureModuleCompleted
      );
      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            host: this.host,
            lets_encrypt: this.isLetsEncryptEnabled,
            http2https: this.isHttpToHttpsEnabled,
            access_token_expire_minutes: Number(this.accessTokenExpireMinutes),
            audit_log_retention_days: Number(this.auditLogRetentionDays),
            default_alert_severity: this.defaultAlertSeverity,
            announcements_enabled: this.announcementsEnabled,
            talon_release_check_enabled: this.talonReleaseCheckEnabled,
            mail_from: this.mailFrom,
          },
          extra: {
            title: this.$t("settings.instance_configuration", {
              instance: this.instanceName,
            }),
            description: this.$t("settings.configuring"),
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
        return;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;

      // reload configuration
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.mg-bottom {
  margin-bottom: $spacing-06;
}

.maxwidth {
  max-width: 38rem;
}

.helper {
  margin-top: -$spacing-05;
  font-size: 0.75rem;
  color: $ui-04;
}
</style>
