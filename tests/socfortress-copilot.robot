*** Settings ***
Library    SSHLibrary
Library    String

*** Variables ***
${TEST_HOST}    copilot.ns8-ci.test

*** Test Cases ***
Check if copilot is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Check if copilot can be configured
    # Starts the pod: MySQL and MinIO, then the backend creates the
    # database and runs its migrations. The task ends once every unit answers.
    ${rc} =    Execute Command
    ...    api-cli run module/${module_id}/configure-module --data '{"host":"${TEST_HOST}","http2https":false,"lets_encrypt":false,"audit_log_retention_days":30,"default_alert_severity":"Medium","announcements_enabled":false}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if copilot configuration reads back without secrets
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/get-configuration --data '{}'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    ${config} =    Evaluate    json.loads('''${output}''')    modules=json
    Should Be Equal    ${config}[host]    ${TEST_HOST}
    Should Be Equal As Integers    ${config}[audit_log_retention_days]    30
    Should Be Equal As Integers    ${config}[access_token_expire_minutes]    1440
    Should Be Equal    ${config}[default_alert_severity]    Medium
    Should Be Equal    ${config}[announcements_enabled]    ${False}
    Should Be Equal    ${config}[jwt_secret_set]    ${True}
    Should Be Equal    ${config}[sso_state_secret_set]    ${True}
    ${secrets} =    Execute Command    runagent -m ${module_id} bash -c 'cat mysql.env minio.env secrets.env | cut -d= -f2- | grep -vx -e copilot -e ""'
    @{values} =    Split To Lines    ${secrets}
    Should Not Be Empty    ${values}
    FOR    ${value}    IN    @{values}
        Should Not Contain    ${output}    ${value}
    END

Check if the secrets stay out of the environment
    ${output}  ${rc} =    Execute Command    runagent -m ${module_id} bash -c 'grep -cE "PASSWORD|SECRET|ENCRYPTION_KEY" environment; stat -c %a mysql.env minio.env secrets.env custom.env copilot.env smarthost.env'
    ...    return_rc=True
    Should Be Equal As Strings    ${output}    0\n600\n600\n600\n600\n600\n600

Check if the frontend answers through Traefik
    ${rc} =    Execute Command    bash -c 'for i in $(seq 1 60); do curl -s -o /dev/null -f --resolve ${TEST_HOST}:80:127.0.0.1 http://${TEST_HOST}/ && exit 0; sleep 5; done; exit 1'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
    ${output}  ${rc} =    Execute Command    curl -s -f --resolve ${TEST_HOST}:80:127.0.0.1 http://${TEST_HOST}/
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Contain    ${output}    SOCFortress CoPilot

Check if the backend API answers through Traefik
    # A public endpoint of the login page: it reads the database
    ${rc} =    Execute Command    bash -c 'for i in $(seq 1 60); do curl -s -o /dev/null -f --resolve ${TEST_HOST}:80:127.0.0.1 http://${TEST_HOST}/api/auth/sso/status && exit 0; sleep 5; done; exit 1'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
    ${output}  ${rc} =    Execute Command    curl -s -f --resolve ${TEST_HOST}:80:127.0.0.1 http://${TEST_HOST}/api/auth/sso/status
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    ${status} =    Evaluate    json.loads('''${output}''')    modules=json
    Should Be Equal    ${status}[sso_enabled]    ${False}

Check if the admin password is in the backend log
    ${output}  ${rc} =    Execute Command    runagent -m ${module_id} bash -c 'podman logs copilot-backend 2>&1 | grep -c "Admin user password"'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Be Equal As Strings    ${output}    1

Check if copilot is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
