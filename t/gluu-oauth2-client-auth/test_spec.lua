local utils = require"test_utils"
local sh, stdout, stderr, sleep, sh_ex =
    utils.sh, utils.stdout, utils.stderr, utils.sleep, utils.sh_ex
local pl_path = require"pl.path"

local host_git_root = os.getenv"HOST_GIT_ROOT"
local git_root = os.getenv"GIT_ROOT"

local JSON = require"JSON"

local test_name = "utils" -- should be in sync with file structure

local docker_compose_prefix = "docker-compose -f " .. git_root .. "/t/" ..test_name .."/docker-compose.yml "
local docker_compose = function(suffix)
    sh(docker_compose_prefix .. suffix)
end

local kong_container_name = test_name .. "_kong_1"


test("kong test", function()
    docker_compose("up -d kong-database")

    -- TODO replace with more stable script
    sleep(5) -- lets postgress chance to start
    --docker_compose("logs kong-database")

    docker_compose("up -d kong-migration")

    -- TODO replace with more stable solution
    sleep(20) -- lets kong chance to start

    docker_compose("up -d oxd-mock")

    docker_compose("up -d kong backend")

    -- TODO replace with more stable solution
    sleep(10) -- lets kong chance to start

    local print_logs = true
    finally(function()
        if print_logs then
            docker_compose("logs kong")
            docker_compose("logs oxd-mock")
        end

        docker_compose("down -v") -- comment this out if you need to see logs after errors
    end)

    local kong_admin_port = stdout("docker inspect --format='{{(index (index .NetworkSettings.Ports \"8001/tcp\") 0).HostPort}}' test1_kong_1")
    local kong_proxy_port = stdout("docker inspect --format='{{(index (index .NetworkSettings.Ports \"8000/tcp\") 0).HostPort}}' test1_kong_1")
    local oxd_port = stdout("docker inspect --format='{{(index (index .NetworkSettings.Ports \"80/tcp\") 0).HostPort}}' test1_oxd-mock_1")

    -- create a Sevice
    local res, err = sh_ex(
        [[curl --fail -i -sS -X POST --url http://localhost:]],kong_admin_port,[[/services/ --data 'name=test1-service' --data 'url=http://backend']]
    )

    sleep(1)

    -- create a Route
    local res, err = sh_ex(
        [[curl --fail -i -sS -X POST  --url http://localhost:]],kong_admin_port,[[/services/test1-service/routes --data 'hosts[]=backend.com']]
    )

    sleep(1)

    -- test it works
    local res, err = sh_ex([[curl --fail -i -sS -X GET --url http://localhost:]], kong_proxy_port,[[/ --header 'Host: backend.com']])


    -- enable plugin for the Service
    local res, err = sh_ex([[
curl --fail -i -sS -X POST  --url http://localhost:]],kong_admin_port,[[/services/test1-service/plugins/  --data 'name=gluu-oauth2-client-auth' \
--data "config.hide_credentials=true" \
--data "config.op_server=stub" \
--data "config.oxd_http_url=http://oxd-mock"]]
    )

    sleep(1)

    -- test it fail with 401
    local res, err = sh_ex([[curl -i -sS -X GET --url http://localhost:]], kong_proxy_port,[[/ --header 'Host: backend.com']])
    assert(res:find("401"))

    local setup_client = {
        scope = { "openid", "uma_protection" },
        op_host = "just_stub",
        authorization_redirect_uri = "https://client.example.com/cb",
        client_name = "test1 plugin",
        grant_types = { "client_credentials" }
    }
    local setup_client_json = JSON:encode(setup_client)

    local res, err = sh_ex(
        [[curl --fail -v -sS -X POST --url http://localhost:]], oxd_port, [[/setup-client --header 'Content-Type: application/json' --data ']],
        setup_client_json, [[']]
    )
    local response = JSON:decode(res)
    assert(response.status == "ok")

    local get_client_token = {
        op_host = "just_stub",
        client_id = response.data.client_id,
        client_secret = response.data.client_secret,
    }
    local get_client_token_json = JSON:encode(get_client_token)
    local res, err = sh_ex(
        [[curl --fail -v -sS -X POST --url http://localhost:]],oxd_port,[[/get-client-token --header 'Content-Type: application/json' --data ']],
        get_client_token_json, [[']]
    )

    local response = JSON:decode(res)
    assert(response.status == "ok")

    local access_token = response.data.access_token

    -- test it works
    local res, err = sh_ex(
        [[curl --fail -i -sS  -X GET --url http://localhost:]],kong_proxy_port,[[/ --header 'Host: backend.com' --header 'Authorization: Bearer ]],
        access_token, [[']]
    )

    -- print_logs = false
end)
