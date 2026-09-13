require "net/http"
require "uri"
require "json"
require "cgi"
require_relative "utils/banner"

MY_PROJECT = "Redtube Miniapp"

GREEN  = "\e[1;32m"
YELLOW = "\e[1;33m"
RED    = "\e[1;31m"
RESET  = "\e[0m"

BASE_URL = "https://redtube-nine.vercel.app"

DEFAULT_CONFIG = {
  "tasks" => {
    "channel_join" => {
      "enabled" => false
    }
  },
  "settings" => {
    "sleep_seconds" => 3600
  }
}

DEVICE_FILE = "device.json"

ANDROID_DEVICES = [
  ["Samsung", "SM-G998B", "Galaxy S21 Ultra"],
  ["Samsung", "SM-S908B", "Galaxy S22 Ultra"],
  ["Samsung", "SM-S918B", "Galaxy S23 Ultra"],
  ["Samsung", "SM-S928B", "Galaxy S24 Ultra"],
  ["Samsung", "SM-A546B", "Galaxy A54"],
  ["Samsung", "SM-A736B", "Galaxy A73"],
  ["Xiaomi", "2201123G", "12 Pro"],
  ["Xiaomi", "2303CRA44A", "13 Pro"],
  ["Xiaomi", "23116PN5BC", "14"],
  ["Xiaomi", "24117RK92G", "14 Ultra"],
  ["OnePlus", "CPH2423", "11 5G"],
  ["OnePlus", "CPH2449", "Nord 3"],
  ["Oppo", "CPH2631", "Reno11 Pro"],
  ["Oppo", "CPH2525", "Find X6"],
  ["Oppo", "CPH2609", "Find N3"],
  ["Vivo", "V2309A", "X90 Pro"],
  ["Vivo", "V2325A", "X100 Pro"],
  ["Realme", "RMX3771", "GT5 Pro"],
  ["Realme", "RMX3740", "11 Pro Plus"],
  ["Google", "Pixel 8", "Pixel 8"],
  ["Google", "Pixel 8 Pro", "Pixel 8 Pro"],
  ["Google", "Pixel 9", "Pixel 9"],
  ["Nokia", "TA-1662", "G42 5G"],
]

ANDROID_VERSIONS = [
  ["12", "32"],
  ["13", "33"],
  ["14", "34"],
  ["15", "35"],
  ["16", "36"],
]

TELEGRAM_VERSIONS = [
  "11.7.4", "11.8.2", "11.9.0", "12.0.1", "12.1.3",
  "12.2.0", "12.3.1", "12.4.0", "12.5.2", "12.6.1",
  "12.7.3", "12.8.0", "12.9.2", "12.9.4",
]

CHROMIUM_VERSIONS = [
  "148", "149", "150", "151", "152", "153", "154",
]

WEBVIEW_APPS = [
  "uz.unnarsx.cherrygram",
  "org.telegram.messenger",
  "org.telegram.messenger.web",
  "org.thunderdog.challegram",
  "ru.sberdevices.telegram",
  "me.teleplus.android",
  "app.nicegram",
  "com.exteragram.messenger",
  "com.radolyn.ayugram",
  "io.nekogram.x",
  "io.nekogram",
  "me.unigram.messenger",
  "com.tgx.messenger.foss",
  "app.nagram",
  "com.hanista.mobogram",
  "ja.yuuri.yuurigram",
]

def log_green(msg)  = puts("#{GREEN}#{msg}#{RESET}")
def log_yellow(msg) = puts("#{YELLOW}#{msg}#{RESET}")
def log_red(msg)    = puts("#{RED}#{msg}#{RESET}")

def mask_ip(ip)
  parts = ip.split(".")
  if parts.length == 4
    "#{parts[0]}*****#{parts[3]}"
  else
    ip[0..2] + "*****" + ip[-3..]
  end
end

def mask_proxy(proxy_str)
  if proxy_str.include?("@")
    rest = proxy_str.split("@").last
    host_port = rest.split(":")
    ip   = host_port[0]
    port = host_port[1] || ""
    "http://user:pass@#{mask_ip(ip)}:#{port}"
  else
    cleaned = proxy_str.sub(/^https?:\/\//, "")
    parts = cleaned.split(":")
    ip   = parts[0]
    port = parts[1] || ""
    "http://user:pass@#{mask_ip(ip)}:#{port}"
  end
rescue
  "http://user:pass@*****"
end

def load_file_lines(path)
  return [] unless File.exist?(path)
  File.readlines(path, chomp: true).map(&:strip).reject(&:empty?)
end

def load_config
  unless File.exist?("config.json")
    File.write("config.json", JSON.pretty_generate(DEFAULT_CONFIG))
    return DEFAULT_CONFIG
  end
  JSON.parse(File.read("config.json"))
end

def get_proxy_url(proxy_str)
  return nil if proxy_str.nil? || proxy_str.empty?
  proxy_str.start_with?("http") ? proxy_str : "http://#{proxy_str}"
end

def extract_user_info(init_data)
  parsed = CGI.parse(init_data)
  user_raw = (parsed["user"] || ["{}"])[0]
  JSON.parse(CGI.unescape(user_raw))
rescue
  {}
end

def load_devices
  return {} unless File.exist?(DEVICE_FILE)
  JSON.parse(File.read(DEVICE_FILE))
rescue
  {}
end

def save_devices(devices)
  File.write(DEVICE_FILE, JSON.pretty_generate(devices))
end

def build_device_profile
  brand, model, _name = ANDROID_DEVICES.sample
  android_version, sdk = ANDROID_VERSIONS.sample
  telegram_version = TELEGRAM_VERSIONS.sample
  chromium_version = CHROMIUM_VERSIONS.sample
  webview_app = WEBVIEW_APPS.sample

  user_agent = "Mozilla/5.0 (Linux; Android #{android_version}; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/#{chromium_version}.0.0.0 Mobile Safari/537.36 Telegram-Android/#{telegram_version} (#{brand} #{model}; Android #{android_version}; SDK #{sdk}; HIGH)"
  sec_ch_ua = "\"Chromium\";v=\"#{chromium_version}\", \"Android WebView\";v=\"#{chromium_version}\", \"Not A(Brand\";v=\"99\""

  {
    "brand"            => brand,
    "model"            => model,
    "android_version"  => android_version,
    "sdk"              => sdk,
    "telegram_version" => telegram_version,
    "chromium_version" => chromium_version,
    "webview_app"      => webview_app,
    "user_agent"       => user_agent,
    "sec_ch_ua"        => sec_ch_ua,
  }
end

def device_for_user(devices, user_id)
  key = user_id.to_s
  return devices[key] if devices[key]

  profile = build_device_profile
  devices[key] = profile
  save_devices(devices)
  profile
end

def build_headers(init_data, device, action_token: nil)
  headers = {
    "accept"               => "*/*",
    "accept-language"      => "en,en-ID;q=0.9,ja-JP;q=0.8,ja;q=0.7,id-ID;q=0.6,id;q=0.5,en-US;q=0.4",
    "cache-control"        => "no-cache",
    "content-type"         => "application/json",
    "origin"               => BASE_URL,
    "pragma"               => "no-cache",
    "priority"             => "u=1, i",
    "referer"              => "#{BASE_URL}/",
    "sec-ch-ua"            => device["sec_ch_ua"],
    "sec-ch-ua-mobile"     => "?1",
    "sec-ch-ua-platform"   => '"Android"',
    "sec-fetch-dest"       => "empty",
    "sec-fetch-mode"       => "cors",
    "sec-fetch-site"       => "same-origin",
    "user-agent"           => device["user_agent"],
    "x-requested-with"     => device["webview_app"],
    "x-telegram-init-data" => init_data,
  }
  headers["x-action-token"] = action_token if action_token
  headers
end

def format_duration(seconds)
  h = seconds / 3600
  m = (seconds % 3600) / 60
  s = seconds % 60
  format("%d:%02d:%02d", h, m, s)
end

def spin_cooldown_wait(seconds, account_index)
  seconds.downto(1) do |remaining|
    print "\r#{YELLOW}Account #{account_index} spin cooldown #{format_duration(remaining)}#{RESET}   "
    $stdout.flush
    sleep 1
  end
  print "\r#{" " * 60}\r"
  $stdout.flush
  sleep 2
end

def ads_cooldown_wait(seconds, account_index)
  seconds.downto(1) do |remaining|
    print "\r#{YELLOW}Account #{account_index} ads cooldown #{format_duration(remaining)}#{RESET}   "
    $stdout.flush
    sleep 1
  end
  print "\r#{" " * 60}\r"
  $stdout.flush
  sleep 2
end

def task_claim_wait(seconds, account_index)
  seconds.downto(1) do |remaining|
    print "\r#{YELLOW}Account #{account_index} task claim retry in #{format_duration(remaining)}#{RESET}   "
    $stdout.flush
    sleep 1
  end
  print "\r#{" " * 60}\r"
  $stdout.flush
end

def cycle_cooldown_wait(seconds)
  seconds.downto(1) do |remaining|
    print "\r#{YELLOW}Next cycle starts in #{format_duration(remaining)}#{RESET}   "
    $stdout.flush
    sleep 1
  end
  print "\r#{" " * 60}\r"
  $stdout.flush
end

def http_post(url_str, headers, payload, proxy_url, tokens: nil, token_key: nil)
  uri = URI.parse(url_str)
  proxy = proxy_url ? URI.parse(proxy_url) : nil

  http_class = proxy ? Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password) : Net::HTTP
  http = http_class.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  req = Net::HTTP::Post.new(uri.request_uri, headers)
  req.body = payload.to_json
  resp = http.request(req)

  if tokens && token_key
    fresh_token = resp["x-action-token"]
    tokens[token_key] = fresh_token if fresh_token
  end

  JSON.parse(resp.body)
rescue
  nil
end

def http_get(url_str, headers, proxy_url, tokens: nil, token_key: nil)
  uri = URI.parse(url_str)
  proxy = proxy_url ? URI.parse(proxy_url) : nil

  http_class = proxy ? Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password) : Net::HTTP
  http = http_class.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  req = Net::HTTP::Get.new(uri.request_uri, headers)
  resp = http.request(req)

  if tokens && token_key
    fresh_token = resp["x-action-token"]
    tokens[token_key] = fresh_token if fresh_token
  end

  JSON.parse(resp.body)
rescue
  nil
end

def fetch_user_info(init_data, proxy, device)
  user = extract_user_info(init_data)
  first_name = user["first_name"] || ""
  payload = { "firstName" => first_name, "refBy" => 6004380466 }
  http_post("#{BASE_URL}/api/user", build_headers(init_data, device), payload, proxy)
end

def fetch_spin_info(init_data, proxy, device, tokens)
  http_get("#{BASE_URL}/api/earn?type=spin", build_headers(init_data, device), proxy, tokens: tokens, token_key: "/api/earn")
end

def do_spin(init_data, proxy, device, tokens, network)
  token = tokens["/api/earn"]
  http_post("#{BASE_URL}/api/earn", build_headers(init_data, device, action_token: token), { "action" => "spin", "network" => network }, proxy, tokens: tokens, token_key: "/api/earn")
end

def fetch_task_info(init_data, proxy, device, tokens)
  http_get("#{BASE_URL}/api/task?type=special", build_headers(init_data, device), proxy, tokens: tokens, token_key: "/api/task")
end

def view_task(init_data, proxy, device, tokens, task_id)
  token = tokens["/api/task"]
  http_post("#{BASE_URL}/api/task", build_headers(init_data, device, action_token: token), { "action" => "viewSpecialTask", "taskId" => task_id }, proxy, tokens: tokens, token_key: "/api/task")
end

def claim_task(init_data, proxy, device, tokens, task_id)
  token = tokens["/api/task"]
  http_post("#{BASE_URL}/api/task", build_headers(init_data, device, action_token: token), { "action" => "completeSpecialTask", "taskId" => task_id }, proxy, tokens: tokens, token_key: "/api/task")
end

def fetch_ads_info(init_data, proxy, device, tokens)
  http_get("#{BASE_URL}/api/earn", build_headers(init_data, device), proxy, tokens: tokens, token_key: "/api/earn")
end

def claim_ad(init_data, proxy, device, tokens, network)
  token = tokens["/api/earn"]
  http_post("#{BASE_URL}/api/earn", build_headers(init_data, device, action_token: token), { "network" => network }, proxy, tokens: tokens, token_key: "/api/earn")
end

def process_spins(init_data, proxy, device, tokens, account_index)
  spin_info = fetch_spin_info(init_data, proxy, device, tokens)
  unless spin_info
    log_red("Account #{account_index} failed to retrieve spin information")
    return
  end

  spins_available = spin_info["spinsAvailable"] || 0
  next_network    = spin_info["nextNetwork"] || "monetag"
  log_yellow("Account #{account_index} available spins #{spins_available}")

  if spins_available <= 0
    log_yellow("Account #{account_index} no spins available at this time")
    return
  end

  spin_count = 0

  loop do
    result = do_spin(init_data, proxy, device, tokens, next_network)

    unless result
      sleep 1
      next
    end

    if result["error"] == "spin_cooldown"
      seconds_left = result["secondsLeft"]
      spin_cooldown_wait(seconds_left, account_index) if seconds_left
      next
    end

    if result["error"] == "invalid_network"
      next_network = result["expectedNetwork"] || next_network
      next
    end

    if result["error"]
      sleep 1
      next
    end

    if result["success"]
      spin_count   += 1
      reward_type   = result["rewardType"] || "unknown"
      reward_amount = result["rewardAmount"] || 0
      spins_left    = result["spinsAvailable"] || 0
      next_network  = result["nextNetwork"] || next_network
      log_green("Account #{account_index} spin #{spin_count} reward #{reward_amount} #{reward_type.upcase} remaining spins #{spins_left}")
      break if spins_left <= 0
    else
      sleep 1
    end
  end
end

def process_tasks(init_data, proxy, device, tokens, account_index, config)
  channel_join_enabled = config.dig("tasks", "channel_join", "enabled")
  channel_join_enabled = false if channel_join_enabled.nil?

  tasks = fetch_task_info(init_data, proxy, device, tokens)
  unless tasks.is_a?(Array)
    log_red("Account #{account_index} failed to retrieve task information")
    return
  end

  pending = tasks.reject { |t| t["completed"] == true }
  log_yellow("Account #{account_index} total tasks #{tasks.length} pending #{pending.length}")

  if pending.empty?
    log_yellow("Account #{account_index} all tasks already completed")
    return
  end

  pending.each do |task|
    task_id           = task["id"]
    title              = task["title"] || "Unknown"
    reward             = task["reward"] || 0
    verification_type  = task["verificationType"] || "normal"

    if verification_type == "verified" && !channel_join_enabled
      next
    end

    view_result = view_task(init_data, proxy, device, tokens, task_id)
    unless view_result && view_result["success"]
      log_red("Account #{account_index} task #{title} claim failed")
      next
    end

    result = nil
    loop do
      result = claim_task(init_data, proxy, device, tokens, task_id)
      break unless result && result["error"] == "Please wait a moment before claiming this task."
      task_claim_wait(5, account_index)
    end

    if result && result["success"]
      balance = result["balance"] || 0
      log_green("Account #{account_index} task #{title} claimed #{reward} points new balance #{balance}")
    else
      log_red("Account #{account_index} task #{title} claim failed")
    end
  end
end

def process_ads(init_data, proxy, device, tokens, account_index)
  ads_info = fetch_ads_info(init_data, proxy, device, tokens)
  unless ads_info.is_a?(Hash)
    log_red("Account #{account_index} failed to retrieve ads information")
    return
  end

  networks = ads_info.select { |k, v| v.is_a?(Hash) && v.key?("watchedToday") }.keys
  state = {}

  networks.each do |network|
    info = ads_info[network]
    state[network] = {
      "watched"       => info["watchedToday"] || 0,
      "limit"         => info["limit"] || 0,
      "cooldown"      => info["cooldownSecondsLeft"] || 0,
      "limit_reached" => info["limitReached"] || false,
    }
  end

  loop do
    all_done = networks.all? do |n|
      state[n]["limit_reached"] || state[n]["watched"] >= state[n]["limit"]
    end
    break if all_done

    made_progress = false

    networks.each do |network|
      s = state[network]
      next if s["limit_reached"] || s["watched"] >= s["limit"]
      next if s["cooldown"] > 0

      result = claim_ad(init_data, proxy, device, tokens, network)
      next unless result

      if result["success"]
        reward        = result["reward"] || 0
        watched_today = result["watchedToday"] || s["watched"]
        limit         = result["limit"] || s["limit"]
        cooldown      = result["cooldownSeconds"] || 0
        limit_reached = result["limitReached"] || false
        log_green("Account #{account_index} ads #{network} claimed #{reward} points watched #{watched_today} of #{limit} next cooldown #{cooldown} seconds")
        state[network]["watched"]       = watched_today
        state[network]["cooldown"]      = cooldown
        state[network]["limit_reached"] = limit_reached
        made_progress = true
      elsif result["error"] == "cooldown"
        state[network]["cooldown"] = result["secondsLeft"] || 0
      elsif result["error"] == "limit_reached"
        state[network]["limit_reached"] = true
      else
        log_red("Account #{account_index} ads #{network} claim failed")
      end
    end

    unless made_progress
      active_cooldowns = networks.select do |n|
        !state[n]["limit_reached"] &&
          state[n]["watched"] < state[n]["limit"] &&
          state[n]["cooldown"] > 0
      end.map { |n| state[n]["cooldown"] }

      next if active_cooldowns.empty?

      min_cd = active_cooldowns.min
      ads_cooldown_wait(min_cd, account_index)

      networks.each do |network|
        if state[network]["cooldown"] > 0
          state[network]["cooldown"] = [0, state[network]["cooldown"] - min_cd].max
        end
      end
    end
  end
end

def process_account(init_data, proxy_str, account_index, first_account, devices, config)
  proxy_url  = get_proxy_url(proxy_str)
  user       = extract_user_info(init_data)
  first_name = user["first_name"] || "Account #{account_index}"
  user_id    = user["id"] || account_index

  device = device_for_user(devices, user_id)
  tokens = { "/api/earn" => nil, "/api/task" => nil }

  puts "" unless first_account

  if proxy_str && !proxy_str.empty?
    masked = mask_proxy(proxy_str)
    log_yellow("Processing account #{account_index} #{first_name} via #{masked}")
  else
    log_yellow("Processing account #{account_index} #{first_name}")
  end

  user_info = fetch_user_info(init_data, proxy_url, device)
  log_red("Account #{account_index} failed to retrieve user info") unless user_info

  process_spins(init_data, proxy_url, device, tokens, account_index)
  process_tasks(init_data, proxy_url, device, tokens, account_index, config)
  process_ads(init_data, proxy_url, device, tokens, account_index)

  log_green("Account #{account_index} all tasks completed for this cycle")
end

def main
  show_banner(MY_PROJECT)

  config        = load_config
  sleep_seconds = config.dig("settings", "sleep_seconds") || 3600

  init_data_list = load_file_lines("data.txt")
  if init_data_list.empty?
    log_red("No accounts found in data.txt")
    return
  end

  proxy_list = File.exist?("proxy.txt") ? load_file_lines("proxy.txt") : []
  devices = load_devices

  loop do
    init_data_list.each_with_index do |init_data, idx|
      account_index = idx + 1
      proxy_str = proxy_list.empty? ? nil : proxy_list[(idx) % proxy_list.length]
      process_account(init_data, proxy_str, account_index, account_index == 1, devices, config)
    end

    log_yellow("All accounts processed sleeping for #{sleep_seconds} seconds")
    cycle_cooldown_wait(sleep_seconds)
    show_banner(MY_PROJECT)
  end
end

trap("INT") do
  puts ""
  log_red("Script stopped by user")
  exit 0
end

main
