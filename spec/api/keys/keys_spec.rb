# Copyright: Copyright (c) 2015 Chef, Inc.
# License: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# TODO All this can be replaced by API instead of ctl once
# the API is implemented.
#
# Anywhere you see "API" in the rspec descriptions and contexts are currently using
# ctl and should be updated to use the API.

require 'json'

describe "/keys endpoint", :keys do

  let(:user) do
    {
    "name" => "pedant-user-#{Time.now.to_i}",
    "public_key" => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArpz8ZFn6ptXTCGJ9WLxw
2EnoxAcWiw1NOtXtZ5G59XUyY9VBIaXDiQeMblG6FMGT5TexZ2uKHsW+WBRHsNUz
Tng/gjYKsbX/vUqOnmlUHqg8a9nvPlNK2UFT9wL93g+4NAudOGsd5DREA/rdQVSy
wRx3NqxpY92J9jcUldUGm3QCvHYA/VTZhdqtIFQP5E3w3eEYCyYVRgXCYztYLdKY
AqpU1SeWxwLBO9t/XF4eezqxf5EvHCOPBxYIxJsl3RPWmAEvLWzefNhrPgGZ3o/u
Fufx8Dq3nPOyFY/wGdHYHeGIkgynxJ4gRoZ5NmmvSWs1338V8yTe8zUqPmeM9eEM
awIDAQAB
-----END PUBLIC KEY-----",
    "private_key" => "-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEArpz8ZFn6ptXTCGJ9WLxw2EnoxAcWiw1NOtXtZ5G59XUyY9VB
IaXDiQeMblG6FMGT5TexZ2uKHsW+WBRHsNUzTng/gjYKsbX/vUqOnmlUHqg8a9nv
PlNK2UFT9wL93g+4NAudOGsd5DREA/rdQVSywRx3NqxpY92J9jcUldUGm3QCvHYA
/VTZhdqtIFQP5E3w3eEYCyYVRgXCYztYLdKYAqpU1SeWxwLBO9t/XF4eezqxf5Ev
HCOPBxYIxJsl3RPWmAEvLWzefNhrPgGZ3o/uFufx8Dq3nPOyFY/wGdHYHeGIkgyn
xJ4gRoZ5NmmvSWs1338V8yTe8zUqPmeM9eEMawIDAQABAoIBAAKU7aJqNiuLU9B2
7FWIi76W8Ssc07eAndi12wnB/NblQbZ6K7lcoxR+mRP0f2TZK9+iwCvASk2ELPlO
a3Tw4g5R9tZtCCFyiHJ7DLrI4eaGJEaP9VqdjqjBr4UidTB4WQfj+BIie1GpeCv6
5JSXtQDn89dKG1DPsL+ENvi0KqHXwgLDxrV1A9uSrxKrc5qSksJX9vH6QcLli5Uo
+Aj0kaMzW7uZMsI/uia+0Bvo7ZSZmlE9kqcQjw7pi6aH/v29a43MvFY8hGuVPa8/
9njxS8yZfekL/dVnSowEVCD25aavq+LU63nTubAngDslcTqElya249yGbZlT10ni
8RuGsdkCgYEA4WLJk/yIqn9qf9LA9E2sov5Tt1itpTgWGrx5lfQzCj2rv4SHoNvM
slOSC621Ym5iQrw9U9QNglp/iQ1XZpo+gtNJuktKROwfOthC7m01S13kq+fvgXod
GDzk5Dc5O7qSMP7PAm3H12pPhtjELIkfOyKhTi1rOlaUIm8NcIzsjJ8CgYEAxlS1
z7+dmmUjp8swwcHpE4Jdv0rayQu93E2URDn9+iX0CINeFT0+71gMdmW7oG9XAF9+
J7psq9swoxjYFXTrtKsDgdYFXZFXXjyf1TW1UiwfaDwZ1uxh15XcaVS4JqtZOujj
vXKGGVZ8EAxcwm5yHDWXFutthgfGHlaObBJaYLUCgYAmBbRb8s5bdQNSbQuAK1pk
ZONamuswZDXWbNVWJsw1fhHrTUBUMsBllROeRL/EyzpoZ7kw2yUsSHgbdtS3ym2h
RGO7udfdqLfcBX/FGUdUX5KkLYyKGz+tRxiWJ3rQSLlA6ruhfUOpY5Xm+cqeeMN8
BmuP9LmSLejvpixuQFfnoQKBgEvvOv0jnC/08UXZIf3NRHPXwhTvj/zRpgunGFFW
8srHpTttMKRpIqN4zqy2HrQ6bNETvrVvRxQ1g9WuOW1dqrEtmNYpHzzH3O+Tvo5f
VeD0S8IY4LvNHVjxY8ZgTXFgwXUwnaF3K6if2Dg8w3cd2kq6qfJ4iSJ773rGIRl3
nWrRAoGAeBs+Wfqv3n5SFpJMcgTE0As0hMeUiMdJxvFoWSVUEXtrZYj3lBtjrZgs
4XQOIrXMXYebfXCA0Z9J7xrBt32gU/tTUHFulI4tfskA9KpMoxdyDATvEvdpH2Q6
I3HH09BqJO9B/kMD16gTqn02PJsU2IB08xy6ta7MrW0yBe5Bwng=
-----END RSA PRIVATE KEY-----",
    }
  end

  let(:user_requestor) do
    Pedant::Requestor.new(user['name'], user['private_key'])
  end

  let(:user_payload) do
    {
      "username" => user['name'],
      "first_name" => user['name'],
      "middle_name" => user['name'],
      "last_name" => user['name'],
      "display_name" => user['name'],
      "email" => "#{user['name']}@#{user['name']}.com",
      "password" => "user-password",
      "public_key" => user['public_key']
    }
  end

  $org = {
      "name" => "pedant-org-#{Time.now.to_i}"
  }

  $org_payload = {
      "name" => $org['name'],
      "full_name" => $org['name']
  }

  let(:client) do
    {
      "name" => "pedant-client-#{Time.now.to_i}",
      "public_key" => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA154iMQBvLORZUQNuZrL6
yz1CF48cgOdVah9ZR0Go9JItNZT4S7Wp0Jt0JzEr6GK2Q/vvmpP6u0foK1rD+Ldy
kXxNHW7w8YXcHlKfpYdeaCc6mgHZ2H5uY0HMTuJoZndka9HeAH8dewwBKX+21y12
81Gt6bj/Wz/SUPz8ICLqx7u/pYMW4KaZ3Q3KJD5AGmhz+NVuYTc8zXDswePnuPTa
S6wP3oadOp9y68rmBYiTMpIcvQSOIjYDt2+0l8MlNfai4+mx0f5u0jV9J8DR4Lr+
8Yy6gp7mr6tDVv8upK4JnlanwXsTKkKHwcbwS5Xwp9rdY2LfiqkryBywFmuA6Qk3
xwIDAQAB
-----END PUBLIC KEY-----",
      "private_key" => "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA154iMQBvLORZUQNuZrL6yz1CF48cgOdVah9ZR0Go9JItNZT4
S7Wp0Jt0JzEr6GK2Q/vvmpP6u0foK1rD+LdykXxNHW7w8YXcHlKfpYdeaCc6mgHZ
2H5uY0HMTuJoZndka9HeAH8dewwBKX+21y1281Gt6bj/Wz/SUPz8ICLqx7u/pYMW
4KaZ3Q3KJD5AGmhz+NVuYTc8zXDswePnuPTaS6wP3oadOp9y68rmBYiTMpIcvQSO
IjYDt2+0l8MlNfai4+mx0f5u0jV9J8DR4Lr+8Yy6gp7mr6tDVv8upK4JnlanwXsT
KkKHwcbwS5Xwp9rdY2LfiqkryBywFmuA6Qk3xwIDAQABAoIBAQC4zNXtPbwLs+NB
Zjl3WCtPij9dRdFeQeeZPykbw5D1nVuWMwnkidzz6GjTNne1gvVIq2OfDvm1DlpU
3kRcpY5SV0EY2v8zYlFYw+QE0VL+3bCCUtfNj/84nypm6fIk8GtnZcZqkohH7/AH
C2lAX701qmnuihqCsN6nf0zwljy31gTErmx128UFWcYCjuNiUghrQo5+hhQyoOMm
B+H1k3pIvwJKQLr2PGUGiMWfUPZ383rLAl5sxa+tglbC78bjpSnMxY8kPgY7Zo2I
xUx8D9Gd+GPw9QQxNAuxFTImB8s3kBRQPj0/PHPiosvoFmMRN2e3rzPjd5yPk8AW
ohaUupXRAoGBAP78s7I1OefQC1ss3H0tcK+BOLH9W+5D0hsPtSGKDaCoh3Wrz+O1
NfCGFLnANTMV7L5S8Gu6fwzRTVbmWGq4FgxtZyDoXoqd+0jQRozktKEKP1+qraho
mT4WSgsm153nlD4lvWmvB6iQ7yNXE9LYkrz6RFFUpKBm/MPA3w+rfx1rAoGBANh5
ZYiLs+Pli9a0aunQjKIf2xy7j3S+xnP127d0nmU79AOABi0dkytMJ09WJk+ZojYo
06ykDoXbKNPR7aaT4ZDLKBR7aqpqljV5norM8+H3HfJ6RTUGUvr5jOYKXd3icU5h
PLGPT+U9AjYKQXmzohuCw+qCIb/XSuTI+TCqKOoVAoGAGpDhd/OrsMcwJ7Oo1THi
x6ZC7ehjp5NRVJhyWqgze0WTt2LLKgI7OG//wMqRwFzMaZfijJbFneRAlokxNQ0w
3uKXGAqdrvt+rrtkXlGFsDGNIL57kUw0iw9vb3IAjOcPvtnXvicKOTnAcIImApWl
1CKO85pJ/Jw+QXbaxpsrhzkCgYAkLb3LYVXSS8XgP0zzANjQK7TKC4rBPzUZokhz
U7k5QBjbEOV3Ws8C2HplZweGHC4hERe3bb/DnUoohJhMU8DKGzn6mlnMW335N/dI
SVKlPFCz+r1gTEtICLcEp0zizXqUV+n13vbCYDzjXTluJph8MpGdutv7HPc2X2RO
PtIRtQKBgBWlO5uGBHI18xqLkzLpXlJMBKmkkS+eODsTGDyZi764I1k7/3toJMtu
F7/ap1IvbXbceH2H604No6DF7zbL+oV4PuWJ5TcQwF8qp2fMlUDmdsiU05Yprgtx
GnjKGKxGVGgUyV0K1c/VM7em4I3zH5XK8aZFPm7hzi3G4SWnnffR
-----END RSA PRIVATE KEY-----",
    }
  end

  let(:client_requestor) do
    Pedant::Requestor.new(client['name'], client['private_key'])
  end

  let(:client_payload) do
    {
      "name" => client['name'],
      "public_key" => client['public_key'],
      "admin" => "true"
    }
  end

  $private_key = "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAw/XmEHkKJW/g9W13EBoRqpy09VTN9wATqY1gNvx55cAjga1f
yzfFJGusgV6+VcH+KjOorVZ5ZcPEs0XdhKs/aGb6nklVejY4AoVJ7D/R261GJVQ0
0rsoixf7CziOpxcC6QR7EbQre3QXyehVTa5xN8/4eb49YaDVJbB1e2LdgQswBvDj
bwwDnU2DQsNKwXsNlkV12HzsqqDtCj8aLPYRXAdCP83X612XI8Md0m+o4oH6E7Qk
7Qr/lD1qObcOXXNiR49ao2LiZ/xIohA1PSzvHRbKpu7+0sdd9tGxC5b6yI5e2+Se
tZkNScbEsu1y5yvpwQJ5MBK9CbPWnsdgU6Y1oQIDAQABAoIBABbDcNdHCDuzFGHO
Nn+DV7wG+ippkId51c7jYmLgz1Q2DqnYtwEHWHpTm7VniRqzL1A9sgF4wx9kL2xX
2FS6A+Kf28sZX7mTpMv+Kcks3Lb1GOnrLzuvjBUkUwBJsKCOVsM0xwsWb9qmcMD+
oTIl6nb+TLHvvHej1D7NkcgkgvCjZQXbY1HCWDw9n94+1gXsoeekjCvfExP2kKA3
Eg72lCEMokFLIMfap7Knep5X2r1o2DKNnOnYYS4a3D9g7i9X0mNjHgd1VWrK/h9t
6hS/ORCuO2BGc48r+CTMOZQ6Na6xlOSbZ6MpXK5tgQnSrI2C1Nc8mndFIlve3CEW
TsJxNPECgYEA4hVTMyV4JxwoW7CYfLg3PfzWUE3XPcr1mHkfvY2QTRW4RJZm276h
x2w1FWUsQaD30qcndefDz+prbwXYSK/RvbEuMXPxexpTWee53d1FrL1xMzIauwWB
OHnCxjWHJxGokAYs62wJXqgwA2TJ16PjwWALsaH0hhAZ+/lUVVY5HO0CgYEA3eQm
x1myMVvKZHkorWSKEBYKGszzZWXrRLxxoxph7h5m0muVYyyEaOBN7mfd+4HZDjDN
IV6dRQiczjxWkKxjEptfdy4NVa3ATlB6rLJpvLX04adGZj+NqOjRxXYzAOl2nk4f
71NYvc3NP4/9ZNk+dh8TCTLeXsFWEAwY0+JbmQUCgYEAzzMaGFLrxnRA7J9xcURn
pJD3XYupi4FaCo5fr5pxOKSCR6HLzPLuU9Vw5RXfNJqw5ce6G434YLIIGi0yJpO0
VvRuUHZhRyA+abQ9HP/xHjpU58Wwx9xorHizMHLYVc8SPETcoDpYb/8WWdXiQpZ6
YryCmx7B+qgBGHROfRNTrpUCgYBLhbX1MABIcHeIjvxbV9bt9rJlwNAu+OuEr6b1
3qrqQwq4H8nuwV4n3ABqXovdaKqZ+941t2BL+Mx2HW9ROntV//AUPmZnfQXxIc8/
LFJ02nGIxEhf0M3EacnMLZjafJvU8b5I1NNldsCfG8EhLBfoWFdAUEIDekZym8tv
gqGuiQKBgQCdPmRwuhaJ0TYmAf7u4s71qZu3Vz3t0zxa5ku/NpY4RNh66iNpZoc8
uAXeHqAfpf/Cr3/kiSVAGKHjKNbvSsIrtjVkDm8aYtCmCOpGsg1YHTsHw6YD5xIs
lHaC2DyJKo7h2v0gzAD9C2LLhDYecFyniCEceNNu7pSqRuLFyuJAOQ==
-----END RSA PRIVATE KEY-----"

  $private_key_filepath = "/tmp/private-key-#{Time.now.to_i}"

  $public_key = "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw/XmEHkKJW/g9W13EBoR
qpy09VTN9wATqY1gNvx55cAjga1fyzfFJGusgV6+VcH+KjOorVZ5ZcPEs0XdhKs/
aGb6nklVejY4AoVJ7D/R261GJVQ00rsoixf7CziOpxcC6QR7EbQre3QXyehVTa5x
N8/4eb49YaDVJbB1e2LdgQswBvDjbwwDnU2DQsNKwXsNlkV12HzsqqDtCj8aLPYR
XAdCP83X612XI8Md0m+o4oH6E7Qk7Qr/lD1qObcOXXNiR49ao2LiZ/xIohA1PSzv
HRbKpu7+0sdd9tGxC5b6yI5e2+SetZkNScbEsu1y5yvpwQJ5MBK9CbPWnsdgU6Y1
oQIDAQAB
-----END PUBLIC KEY-----"

  $public_key_filepath = "/tmp/public-key-#{Time.now.to_i}.pub"

  $alt_private_key = "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA2YewTVJI52IrzCwv5KzXvufn6QQkqiwEdh3OPdaeolfciywZ
ZFlRB57fJbK/cLuqM4/lxe/9Xxoa42Ct2RZoV5i2EYSNSa2snQwupRSge2UatR5Z
+QcLaCXqCR/n+6c5+JSSGwOKOuuiD4EKAGf2RwE6wlba9rWArmnMr/sGA5Ox6ogp
oE+jmD1FkKALDMJ7LZaDZ2kJVXXYKKnijnZHO++LhAu3gC547wnfO4JoX2StYqHN
9OjTJK9YRw45Zq7l3W54W+6dHTLzsgHravWed6t3m7JfBIZft6U4ZtPY5LGK1qPS
PDGu8bwn6vJ62Tcf3fzuI2i6x3WWiM9XQilOuQIDAQABAoIBADVF58Vn63bPMg60
m54TPlsAjGkinKAYW5dZwVKfpwX3Ionq6OUMgq2tGNUwq3W+X/Z0vT72gUSzLfaV
jL3noPIi8iPkJH3wzJ9BhoLjRFIz9pB4uGwmb4K4FlLZv4R/9dCNAiMfgNDhODU3
0u06iLPm9y70+ncFCFiujHRks5pYM5JHMucgD6jjNA9sOqc+RlnFatCVwREb/OXr
5G7oxWw3tM+cmwmtkufBZeAsUZL3ITM67dmozOzBfgvGIf/4EkPNp69JDRubuI8h
6m75gQYnfItiOPqVgJnCK6yxvl91ivZuTeLHIk3d3SPD7oMozwuW1ZOIg+68tlmh
pAcVq6ECgYEA/QjqvN3MA95oyq8Za3I5k3idqdzjhIWRhDayx+WWWxTrGfQCFdsK
O8x+nSrNqr5RudTwIuicdrVWt9/QN4e2K6vZbi49dKDCw6RjUW79GFs+NSStIZrw
rF78j8PIX6GUmYoNoi1FTZ0MkrSPW6lkEIAcHDnx1C4+M0SbQYa9+j0CgYEA3BRC
pk2FNNg/xwyF20wsPb3Hvu+rGljSuASVGckbUMg5OOL83Gajm4G6y6BRcGjzPWWg
Cr1Vqqldv+64URPsyvmphyYespJvrLS82ZRLuEux5eBX0vK/mUN/IjH3ra/k+5JM
8IcLLbtm9jH/8Hekk/hPPYF/+A9VOqbfC0oEui0CgYAXT/kAiZbATH9vHQ7EfXOc
iKJOAhHcJcowWjHChP6DSbwXWgnPJa0dsUuBA26Laplw+5NcQ/4WWcKxkidG1nQM
NfsEUbJLynvnNoAIAqfC1LU4hDaHQBUobF/shucxGFvugW+cH3uhGPUNlyEWGtcj
RgpQ9222VMRaSNndAaMDKQKBgAQSx+0GEEobGosXmz6k2UjHQ3QwQW16aWQIia3x
f/Ttz8lSwjVeHPca3pc4P2miN6ZSRDUOrhA7lEWiKH0vrjlPh6i9tuG9Ph3nNnuc
eA5QMFm93kJERfGTQz4hyKDJWaaiXZQyG63cAxrZcBBGVqB6fxT3WaQAvKYaQpSV
6SJ9AoGBAL7Zg4LPhHtQ5xwOeLgqKMXJJvX56F8BiYMXpNqVhvrSwgYOCUXiouDu
0GFNwlun+qgTAxYaJWS55c3jUe8ati/OrMOr62WlfUzNoY1ziJfbL/S0xXKC/SBE
slFU7wOOLWfOPho31gOm1siG675SXTg8efNm/koyU0LK4KuT8WJE
-----END RSA PRIVATE KEY-----"

  $alt_private_key_filepath = "/tmp/alt-private-key-#{Time.now.to_i}"

  $alt_public_key = "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2YewTVJI52IrzCwv5KzX
vufn6QQkqiwEdh3OPdaeolfciywZZFlRB57fJbK/cLuqM4/lxe/9Xxoa42Ct2RZo
V5i2EYSNSa2snQwupRSge2UatR5Z+QcLaCXqCR/n+6c5+JSSGwOKOuuiD4EKAGf2
RwE6wlba9rWArmnMr/sGA5Ox6ogpoE+jmD1FkKALDMJ7LZaDZ2kJVXXYKKnijnZH
O++LhAu3gC547wnfO4JoX2StYqHN9OjTJK9YRw45Zq7l3W54W+6dHTLzsgHravWe
d6t3m7JfBIZft6U4ZtPY5LGK1qPSPDGu8bwn6vJ62Tcf3fzuI2i6x3WWiM9XQilO
uQIDAQAB
-----END PUBLIC KEY-----"

  $alt_public_key_filepath = "/tmp/alt-public-key-#{Time.now.to_i}.pub"

  # TODO remove this after we have APIs in place, since we can just pass
  # strings then
  #
  # write our key files to temp
  before(:all) do
    File.open($private_key_filepath, 'w') {|f| f.write($private_key) }
    File.open($public_key_filepath, 'w') {|f| f.write($public_key) }
    File.open($alt_private_key_filepath, 'w') {|f| f.write($alt_private_key) }
    File.open($alt_public_key_filepath, 'w') {|f| f.write($alt_public_key) }

    # org is static in the tests, only create once
    post("#{platform.server}/organizations", superuser, :payload => JSON.generate($org_payload))
  end

  after(:all) do
    File.delete($private_key_filepath)
    File.delete($public_key_filepath)
    File.delete($alt_private_key_filepath)
    File.delete($alt_public_key_filepath)

    # clean up org
    delete("#{platform.server}/organizations/#{$org['name']}/clients/#{$org['name']}-validator", superuser)
    delete("#{platform.server}/organizations/#{$org['name']}", superuser)
  end

  # create user, org, and client before each test
  before(:each) do
    post("#{platform.server}/users", superuser, :payload => JSON.generate(user_payload))
    post("#{platform.server}/organizations/#{$org['name']}/clients", superuser, :payload => JSON.generate(client_payload))
  end

  # delete user, org, and client after each test
  after(:each) do
    delete("#{platform.server}/users/#{user['name']}", superuser)
    delete("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", superuser)
  end

  context "when a single key exists for a user" do
    context "when the key is uploaded via POST /user" do
      it "should authenticate against the single key" do
        get("#{platform.server}/users/#{user['name']}", Pedant::Requestor.new(user['name'], user['private_key'])).should look_like({:status => 200})
      end
    end

    context "when the default key has been changed via the keys API" do
      before(:each) do
        system("chef-server-ctl delete-user-key #{user['name']} default")
        system("chef-server-ctl add-user-key #{user['name']} #{$alt_public_key_filepath} --key-name default")
      end
      it "should authenticate against the updated key" do
        get("#{platform.server}/users/#{user['name']}", Pedant::Requestor.new(user['name'], $alt_private_key)).should look_like({:status => 200})
      end
      it "should break for original default key" do
        get("#{platform.server}/users/#{user['name']}", Pedant::Requestor.new(user['name'], user['private_key'])).should look_like({:status => 401})
      end
    end
  end

  context "when a single key exists for a client" do
    context "when the key is uploaded via POST /clients" do
      it "should authenticate against the single key" do
        get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", Pedant::Requestor.new(client['name'], client['private_key'])).should look_like({:status => 200})
      end
    end

    context "when the default key has been changed via the keys API" do
      before(:each) do
        system("chef-server-ctl delete-client-key #{$org['name']} #{client['name']} default")
        system("chef-server-ctl add-client-key #{$org['name']} #{client['name']} #{$public_key_filepath} --key-name default")
      end
      it "should authenticate against the updated key" do
        get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", Pedant::Requestor.new(client['name'], $private_key)).should look_like({:status => 200})
      end
      it "should break for original default key" do
        get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", Pedant::Requestor.new(client['name'], client['private_key'])).should look_like({:status => 401})
      end
    end
  end

  context "when a key is deleted for a user" do
    before(:each) do
      system("chef-server-ctl add-user-key #{user['name']} #{$alt_public_key_filepath} --key-name key-#{Time.now.to_i}")
    end
    it "should not longer be returned by the API" do
      system("chef-server-ctl delete-user-key #{user['name']} key-#{Time.now.to_i}")
      `chef-server-ctl list-user-keys #{user['name']}`.should_not include("key-#{Time.now.to_i}")
    end
    it "should still contain other keys not yet deleted" do
      system("chef-server-ctl delete-user-key #{user['name']} key-#{Time.now.to_i}")
      `chef-server-ctl list-user-keys #{user['name']}`.should include("default")
    end
  end

  context "when a key is deleted for a client" do
    before(:each) do
      system("chef-server-ctl add-client-key #{$org['name']} #{client['name']} #{$alt_public_key_filepath} --key-name key-#{Time.now.to_i}")
    end
    it "should not longer be returned by the API" do
      system("chef-server-ctl delete-client-key #{$org['name']} #{client['name']} key-#{Time.now.to_i}")
      `chef-server-ctl list-client-keys #{$org['name']} #{client['name']}`.should_not include("key-#{Time.now.to_i}")
    end
    it "should still contain other keys not yet deleted" do
      system("chef-server-ctl delete-client-key #{$org['name']} #{client['name']} key-#{Time.now.to_i}")
      `chef-server-ctl list-client-keys #{$org['name']} #{client['name']}`.should include("default")
    end
  end

  context "when multiple keys exist for a user" do
    before(:each) do
      system("chef-server-ctl add-user-key #{user['name']} #{$alt_public_key_filepath} --key-name alt-key-#{Time.now.to_i}")
      system("chef-server-ctl add-user-key #{user['name']} #{$public_key_filepath} --key-name key-#{Time.now.to_i}")
    end
    context "should properly authenticate against either keys" do
      it "should properly authenticate against the second key" do
        get("#{platform.server}/users/#{user['name']}", Pedant::Requestor.new(user['name'], $private_key)).should look_like({:status => 200})
      end
      it "should properly authenticate against the first key" do
        get("#{platform.server}/users/#{user['name']}", Pedant::Requestor.new(user['name'], $alt_private_key)).should look_like({:status => 200})
      end
    end
  end

  context "when multiple keys exist for a client" do
    before(:each) do
      system("chef-server-ctl add-client-key #{$org['name']} #{client['name']} #{$alt_public_key_filepath} --key-name alt-key-#{Time.now.to_i}")
      system("chef-server-ctl add-client-key #{$org['name']} #{client['name']} #{$public_key_filepath} --key-name key-#{Time.now.to_i}")
    end
    context "should properly authenticate against either keys" do
      it "should properly authenticate against the first key" do
        get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", Pedant::Requestor.new(client['name'], $private_key)).should look_like({:status => 200})
      end
      it "should properly authenticate against the second key" do
        get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", Pedant::Requestor.new(client['name'], $alt_private_key)).should look_like({:status => 200})
      end
    end
  end

  context "when a user key has an expiration date and isn't expired" do
    before(:each) do
      system("chef-server-ctl add-user-key #{user['name']} #{$public_key_filepath} --key-name key-#{Time.now.to_i} --expiration-date 2017-12-24T21:00:00")
    end
    it "should authenticate against the key" do
      get("#{platform.server}/users/#{user['name']}", Pedant::Requestor.new(user['name'], $private_key)).should look_like({:status => 200})
    end
  end

  context "when a client key has an expiration date and isn't expired" do
    before(:each) do
      system("chef-server-ctl add-client-key #{$org['name']} #{client['name']} #{$public_key_filepath} --key-name key-#{Time.now.to_i} --expiration-date 2017-12-24T21:00:00")
    end
    it "should authenticate against the key" do
      get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", Pedant::Requestor.new(client['name'], $private_key)).should look_like({:status => 200})
    end
  end

  context "when a key is expired for a user" do
    before(:each) do
      system("chef-server-ctl add-user-key #{user['name']} #{$public_key_filepath} --key-name key-#{Time.now.to_i} --expiration-date 2012-12-24T21:00:00")
    end
    it "should fail against the expired key" do
      get("#{platform.server}/users/#{user['name']}", Pedant::Requestor.new(user['name'], $private_key)).should look_like({:status => 401})
    end
    it "should succeed against other keys" do
      get("#{platform.server}/users/#{user['name']}", Pedant::Requestor.new(user['name'], user['private_key'])).should look_like({:status => 200})
    end
  end

  context "when a key is expired for a client" do
    before(:each) do
      system("chef-server-ctl add-client-key #{$org['name']} #{client['name']} #{$public_key_filepath} --key-name key-#{Time.now.to_i} --expiration-date 2012-12-24T21:00:00")
    end
    it "should fail against the expired key" do
      get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", Pedant::Requestor.new(client['name'], $private_key)).should look_like({:status => 401})
    end
    it "should succeed against other keys" do
      get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", Pedant::Requestor.new(client['name'], client['private_key'])).should look_like({:status => 200})
    end
  end

  context "when the default key for a user exists" do
    it "the public_key field returned by GET /users/:user and from the keys table should be the same" do
      user_api_public_key = JSON.parse(get("#{platform.server}/users/#{user['name']}", superuser))['public_key']
      `chef-server-ctl list-user-keys #{user['name']}`.should include(user_api_public_key)
    end
  end

  context "when the default key for a client exists" do
    it "should return public_key field returned by GET /organization/:org/clients/:client and from the keys table should be the same" do
      client_api_public_key = JSON.parse(get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", superuser))['public_key']
      `chef-server-ctl list-client-keys #{$org['name']} #{client['name']}`.should include(client_api_public_key)
    end
  end

  context "when the default key is updated for a user via a PUT to /users" do
    before(:each) do
      original_data = JSON.parse(get("#{platform.server}/users/#{user['name']}", superuser))
      original_data['public_key'] = $public_key
      put("#{platform.server}/users/#{user['name']}", superuser, :payload => JSON.generate(original_data))
    end
    context "when the default key has already been deleted" do
      before(:each) do
        system("chef-server-ctl delete-user-key #{user['name']} default")
        original_data = JSON.parse(get("#{platform.server}/users/#{user['name']}", superuser))
        original_data['public_key'] = $public_key
        put("#{platform.server}/users/#{user['name']}", superuser, :payload => JSON.generate(original_data))
      end
      # TODO: this is the current behavior but is probably wrong
      it "should still (wrongly) be shown in the user's record" do
        JSON.parse(get("#{platform.server}/users/#{user['name']}", superuser))['public_key'].should include($public_key)
      end
      it "should not be shown via data from keys table" do
        `chef-server-ctl list-user-keys #{user['name']}`.should_not include($public_key)
      end
      it "should not be able to authenticate with the default key" do
        get("#{platform.server}/users/#{user['name']}", Pedant::Requestor.new(user['name'], $private_key)).should look_like({:status => 401})
      end
    end
    context "when the default key exists" do
      it "should update the default key in the keys table" do
        `chef-server-ctl list-user-keys #{user['name']}`.should include($public_key)
      end
      it "should no longer contain the old default key" do
        `chef-server-ctl list-user-keys #{user['name']}`.should_not include(user['public_key'])
      end
      it "should return the new key from the /users endpoint" do
        JSON.parse(get("#{platform.server}/users/#{user['name']}", superuser))['public_key'].should include($public_key)
      end
    end
  end

  context "when the default key is updated for a client via a PUT to /organizations/:org/clients" do
    before(:each) do
      original_data = JSON.parse(get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", superuser))
      original_data['public_key'] = $public_key
      put("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", superuser, :payload => JSON.generate(original_data))
    end
    context "when the default key has already been deleted" do
      before(:each) do
        system("chef-server-ctl delete-client-key #{$org['name']} #{client['name']} default")
        original_data = JSON.parse(get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", superuser))
        original_data['public_key'] = $public_key
        put("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", superuser, :payload => JSON.generate(original_data))
      end
      # TODO: this is the current behavior but is probably wrong
      it "should still (wrongly) be shown in the clients's record" do
        JSON.parse(get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", superuser))['public_key'].should include($public_key)
      end
      it "should not be shown via data from keys table" do
        `chef-server-ctl list-client-keys #{$org['name']} #{client['name']}`.should_not include($public_key)
      end
      it "should not be able to authenticate with the default key" do
        get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", Pedant::Requestor.new(client['name'], $private_key)).should look_like({:status => 401})
      end
    end
    context "when the default key exists" do
      it "should update the default key in the keys table" do
        `chef-server-ctl list-client-keys #{$org['name']} #{client['name']}`.should include($public_key)
      end
      it "should no longer contain the old default key" do
        `chef-server-ctl list-client-keys #{$org['name']} #{client['name']}`.should_not include(user['public_key'])
      end
      it "should return the new key from the /users endpoint" do
        JSON.parse(get("#{platform.server}/organizations/#{$org['name']}/clients/#{client['name']}", superuser))['public_key'].should include($public_key)
      end
    end
  end

  context "when a user and client with the same name exist" do
    before(:each) do
      # give user same name as client
      delete("#{platform.server}/users/#{user['name']}", superuser)
      user['name'] = client['name']
      # post a user with the same name as the client, but with the other public key
      payload = {
        "username" => client['name'],
        "first_name" => client['name'],
        "middle_name" => client['name'],
        "last_name" => client['name'],
        "display_name" => client['name'],
        "email" => "#{client['name']}@#{client['name']}.com",
        "password" => "client-password",
        "public_key" => user['public_key']
      }
      post("#{platform.server}/users", superuser, :payload => JSON.generate(payload))
    end
    after do
      post("#{platform.server}/users/#{client['name']}", superuser)
    end
    # note that clients cannot read from /users/:user by default
    it "should not allow client to query /users/:user" do
      get("#{platform.server}/users/#{user['name']}", Pedant::Requestor.new(client['name'], client['private_key'])).should look_like({:status => 401})
    end
    it "should allow user to query /users/:user" do
      get("#{platform.server}/users/#{user['name']}", Pedant::Requestor.new(client['name'], user['private_key'])).should look_like({:status => 200})
    end
  end
end
