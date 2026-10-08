local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- .env 파일 파싱 함수
local function loadEnv(filePath)
    local env = {}
    local path = filePath or ".env"
    
    if isfile and isfile(path) and readfile then
        local content = readfile(path)
        for line in string.gmatch(content, "[^\r\n]+") do
            -- 주석(#) 생략 및 key=value 추출
            if not string.match(line, "^%s*#") and string.match(line, "=") then
                local key, val = string.match(line, "^%s*([^=]+)%s*=%s*(.-)%s*$")
                if key and val then
                    -- 양쪽 따옴표(" 또는 ') 제거
                    val = string.gsub(val, "^[\"'](.-)[\"']$", "%1")
                    env[key] = val
                end
            end
        end
    end
    return env
end

-- 환경 변수 로드
local env = loadEnv(".env")
local WEBHOOK_URL = env["DISCORD_WEBHOOK_URL"]

if not WEBHOOK_URL or WEBHOOK_URL == "" then
    warn("[Error] .env 파일에서 DISCORD_WEBHOOK_URL을 로드할 수 없습니다.")
    return
end

-- 익스큐터 환경별 HTTP 요청 함수 호환성 처리
local httpRequest = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)

if not httpRequest then
    warn("현재 사용 중인 익스큐터가 HTTP 요청 함수(request)를 지원하지 않습니다.")
    return
end

-- 익스큐터 이름 감지
local function getExecutorName()
    if identifyexecutor then
        local name, version = identifyexecutor()
        return version and (name .. " " .. version) or name
    elseif getexecutorname then
        return getexecutorname()
    end
    return "Unknown Executor"
end

-- AccountAge(일 수)를 기반으로 생성 날짜 추정 (YYYY-MM-DD)
local accountAgeDays = player.AccountAge
local estimatedCreationTimestamp = os.time() - (accountAgeDays * 86400)
local creationDateStr = os.date("%Y-%m-%d", estimatedCreationTimestamp)

-- 디스코드 임베드 페이로드 작성
local payload = {
    ["embeds"] = {
        {
            ["title"] = "📊 로블록스 세션 정보",
            ["color"] = 3447003, -- 파란색 계열
            ["fields"] = {
                {
                    ["name"] = "👤 유저 정보",
                    ["value"] = string.format("@%s (%s)", player.Name, player.DisplayName),
                    ["inline"] = false
                },
                {
                    ["name"] = "🆔 유저 ID",
                    ["value"] = tostring(player.UserId),
                    ["inline"] = true
                },
                {
                    ["name"] = "📅 계정 생성일",
                    ["value"] = string.format("%s (약 %d일 전)", creationDateStr, accountAgeDays),
                    ["inline"] = true
                },
                {
                    ["name"] = "🎮 접속한 체험 ID",
                    ["value"] = tostring(game.PlaceId),
                    ["inline"] = true
                },
                {
                    ["name"] = "⏰ 현지 시간",
                    ["value"] = os.date("%Y-%m-%d %H:%M:%S"),
                    ["inline"] = true
                },
                {
                    ["name"] = "⚙ 익스큐터 이름",
                    ["value"] = getExecutorName(),
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "Roblox LocalScript Logger"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
}

-- 디스코드 웹훅 전송
local success, result = pcall(function()
    return httpRequest({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(payload)
    })
end)

if success then
    print("[Success] 디스코드 웹훅으로 정보가 성공적으로 전송되었습니다.")
else
    warn("[Error] 웹훅 전송 실패:", result)
end
