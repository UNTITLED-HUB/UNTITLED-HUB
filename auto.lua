local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local WEBHOOK_URL = "https://discord.com/api/webhooks/1555656375517052928/b1FfFfm4u_8skT2lQn7creKshWLZoNGVPte381bdFMqqNJm4i7UG6PJ355cqZloaxb0b"

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
                    ["name"] = "⚙️️ 익스큐터 이름",
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
