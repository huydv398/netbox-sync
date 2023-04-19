
# NetBox-Sync
**IMPORTANT: Đọc kỹ trước khi chạy chương trình**

Tài liệu được sao chép và tham khảo [Tại đây](https://github.com/bb-Ricardo/netbox-sync/blob/main/README.md)
## Principles
## Requirements
### Software
* python >= 3.6
* packaging
* urllib3==1.26.9
* wheel
* requests==2.27.1
* pyvmomi==7.0.3
* aiodns==2.0.0
* setuptools>=62.00.0
* pyyaml==6.0

### Environment
* NetBox >= 2.9
#### Source: VMWare (if used)
* VMWare vCenter >= 6.0
#### Source: check_redfish (if used)
* check_redfish >= 1.2.0

# Installing
* here we assume we install in ```/opt```

## RedHat based OS
* on RedHat/CentOS 7 you need to install python3.6 and pip from EPEL first
* on RedHat/CentOS 8 systems the package name changed to `python3-pip`
```shell
yum install python36-pip
```

## Ubuntu 18.04 & 20.04 && 22.04
```shell
apt-get update && apt-get install python3-venv
```

## Sao chép repo và cài đặt phụ thuộc
* Nếu bạn cần sử dụng python 3.6 thì bạn cần có `requirements_3.6.txt` để cài đặt các yêu cầu
* Tải xuống và thiết lập môi trường ảo
```shell
cd /opt
git clone https://github.com/huydv398/netbox-sync.git
cd netbox-sync
python3 -m venv .venv
. .venv/bin/activate
pip3 install --upgrade pip || pip install --upgrade pip
pip3 install wheel || pip install wheel
pip3 install -r requirements.txt || pip install -r requirements.txt
```

### Đồng bộ hóa tag VMware (nếu cần)
Phải cài đặt `vsphere-automation-sdk` nếu các thẻ phải được đồng bộ hóa từ vCenter sang NetBox
* giả sử chúng ta vẫn đang ở trong một môi trường ảo được kích hoạt
```shell
pip install --upgrade git+https://github.com/vmware/vsphere-automation-sdk-python.git
```

## NetBox API token
Để cập nhật dữ liệu trong NetBox, bạn cần có NetBox API token.
* API token với tất cả các quyền (đọc, viết) ngoại trừ:
  * auth
  * secrets
  * users

Một mô tả ngắn có thể được tìm thấy [here](https://docs.netbox.dev/en/stable/integrations/rest-api/#authentication)

# Running the script

```
usage: netbox-sync.py [-h] [-c settings.ini [settings.ini ...]] [-g]
                      [-l {DEBUG3,DEBUG2,DEBUG,INFO,WARNING,ERROR}] [-n] [-p]

Sync objects from various sources to NetBox

Version: 1.4.0 (2023-03-20)
Project URL: https://github.com/bb-ricardo/netbox-sync

options:
  -h, --help            show this help message and exit
  -c settings.ini [settings.ini ...], --config settings.ini [settings.ini ...]
                        points to the config file to read config data from
                        which is not installed under the default path
                        './settings.ini'
  -g, --generate_config
                        generates default config file.
  -l {DEBUG3,DEBUG2,DEBUG,INFO,WARNING,ERROR}, --log_level {DEBUG3,DEBUG2,DEBUG,INFO,WARNING,ERROR}
                        set log level (overrides config)
  -n, --dry_run         Operate as usual but don't change anything in NetBox.
                        Great if you want to test and see what would be
                        changed.
  -p, --purge           Remove (almost) all synced objects which were create
                        by this script. This is helpful if you want to start
                        fresh or stop using this script.
```

## TESTING
Bạn nên đặt mức nhật ký thành `DEBUG2` theo cách này, chương trình sẽ cho bạn biết điều gì đang xảy ra và tại sao. Ngoài ra, hãy sử dụng tùy chọn chạy khô -n ngay từ đầu để tránh những thay đổi trực tiếp trong NetBox.

`vi settings-example.yaml`
```
[common]

log_level = DEBUG2
```
## Configuration
Có hai cách để xác định cấu hình. Bất kỳ sự kết hợp nào của (các) tệp cấu hình và biến môi trường đều có thể.
* config files (the [default config](settings-example.ini) file name is set to `./settings.ini`.)
* environment variables


### Config files
Following config file types are supported:
* ini
* yaml
Cấu hình từ các biến môi trường sẽ được ưu tiên hơn các định nghĩa tệp cấu hình. Trong source tôi thực hiện sửa [file](settings-example.ini)

### Environment variables
Mỗi cài đặt có thể được xác định trong tệp cấu hình cũng có thể được xác định bằng biến môi trường.

Tiền tố cho tất cả các biến môi trường được sử dụng trong netbox-sync là: `NBS`

Đối với cấu hình trong phần `common` và `netbox`, một biến được xác định như thế này
```
<PREFIX>_<SECTION_NAME>_<CONFIG_OPTION_KEY>=value
```

Ví dụ sau đại diện cho cùng một cấu hình:
```yaml
# yaml config example
common:
  log_level: DEBUG2
netbox:
  host_fqdn: netbox-host.example.com
  prune_enabled: true
```
```bash
# this variable definition is equal to the yaml config sample above
NBS_COMMON_LOG_LEVEL="DEBUG2"
NBS_netbox_host_fqdn="netbox-host.example.com"
NBS_NETBOX_PRUNE_ENABLED="true"
```

Bằng cách này, có thể hiển thị ví dụ `NBS_NETBOX_API_KEY` chỉ thông qua một biến env.

Định nghĩa cấu hình cho `sources` cần được xác định bằng index. áp dụng các điều kiện sau:
* một sources duy nhất cần sử dụng cùng một index
* index có thể là số hoặc tên (nhưng chứa bất kỳ ký tự đặc biệt nào để hỗ trợ phân tích cú pháp env var)
* sources cần được đặt tên với biến _NAME

Ví dụ về xác định nguồn với các biến cấu hình và môi trường.
```ini
; example for a source
[source/example-vcenter]
enabled = True
type = vmware
host_fqdn = vcenter.example.com
username = vcenter-readonly
```
```bash
# define the password on command line
# here we use '1' as index
NBS_SOURCE_1_NAME="example-vcenter"
NBS_SOURCE_1_PASSWORD="super-secret-and-not-saved-to-the-config-file"
NBS_SOURCE_1_custom_dns_servers="10.0.23.23, 10.0.42.42"
```

Ngay cả khi chỉ xác định một biến nguồn như `NBS_SOURCE_1_PASSWORD`, `NBS_SOURCE_1_NAME` cần được xác định là để liên kết với định nghĩa nguồn theo.

## Cron job
Để đồng bộ hóa tất cả các mục thường xuyên, bạn có thể thêm một công việc định kỳ như thế này
```
 # NetBox Sync
 23 */2 * * *  /opt/netbox-sync/.venv/bin/python3 /opt/netbox-sync/netbox-sync.py >/dev/null 2>&1
```

File cấu hình cuối cùng:
```
egrep -v "^#|^*#|^$|^;" settings-example.ini 

```

Thay các trường giá trị tương ứng với hệ thống của bạn
```
[common]
log_level = DEBUG2
[netbox]
api_token = ca5558xxxxxxxxxxxxxxxxxxxxb284d7753ae5
host_fqdn = nb.netbox-note.vn
[source/vcenter-name]
type = vmware
host_fqdn = vcenter.vmware.local
username = administrator@vsphere.local
password = pass_vcenter
[source/my-redfish-example]
type = check_redfish
inventory_file_path = check_redfish
permitted_subnets = permitted_subnets = 172.16.0.0/12, 10.0.0.0/8, 192.168.0.0/16, 10.0.11.0/24 
```
# How it works
**Đọc kỹ trước khi thực hiện**

Thực hiện lệnh để chạy source:
```
./netbox-sync.py -c settings-example.ini
```
## Basic structure
Chương trình được thực hiện như sau:
1. Phân tích cú pháp & xác thực các cấu hình
2. Khởi tạo tất cả các source và thiết lập kết nối với NetBox
3. Đọc dữ liệu hiện tại từ NetBox
4. Đọc dữ liệu từ tất cả các nguồn và thêm/cập nhật các đối tượng trong bộ nhớ
5. Cập nhật dữ liệu trong NetBox dựa trên dữ liệu từ các sources
6. Bỏ bớt các đối tượng đã cũ

## NetBox connection
Yêu cầu tất cả các đối tượng NetBox hiện tại. Sử dụng bộ nhớ đệm bất cứ khi nào có thể. Các đối tượng phải cung cấp thuộc tính "last_updated" để hỗ trợ bộ nhớ đệm cho loại đối tượng này.

Thực sự thực hiện yêu cầu và thử lại x lần nếu hết thời gian yêu cầu. Chương trình sẽ thoát nếu tất cả các lần thử lại không thành công!

## Supported sources
Kiểm tra các tài liệu cho các nguồn khác nhau
* [vmware](docs/source_vmware.md)
* [check_redfish](docs/source_check_redfish.md)

Nếu bạn có nhiều phiên bản vCenter hoặc thư mục check_redfish, chỉ cần thêm một nguồn khác có `cùng loại` vào cùng một tệp.

Ví dụ:

Example:
```ini
[source/vcenter-hanoi]

enabled = True
host_fqdn = vcenter1.hanoi.example.com

[source/vcenter-hcm]

enabled = True
host_fqdn = vcenter2.hcm.example.com

[source/redfish-hardware]

type = check_redfish
inventory_file_path = /opt/redfish_inventory
```


## Loại bỏ
Bỏ bớt các đối tượng đã cũ nếu chúng không còn hiện diện trong bất kỳ nguồn nào. Đầu tiên, chúng sẽ được đánh dấu là Orphaned và sau X (tùy chọn cấu hình) ngày, chúng sẽ bị xóa khỏi NetBox.

Objects subjected to pruning:
* devices
* VMs
* device interfaces
* VM interfaces
* IP addresses

Tất cả các đối tượng khác được tạo (tức là: VLANs, cluster, manufacturers) sẽ giữ thẻ nguồn nhưng sẽ không bị xóa. Luận đề là các đối tượng "được chia sẻ" có thể được sử dụng bởi các đối tượng NetBox khác nhau

## Docker

Run the application in a docker container. You can build it yourself or use the ones from docker hub.

Available here: [bbricardo/netbox-sync](https://hub.docker.com/r/bbricardo/netbox-sync)

* The application working directory is ```/app```
* Required to mount your ```settings.ini```

To build it by yourself just run:
```shell
docker build -t bbricardo/netbox-sync:latest .
```

To start the container just use:
```shell
docker run --rm -it -v $(pwd)/settings.ini:/app/settings.ini bbricardo/netbox-sync:latest
```

## Kubernetes

Run the containerized application in a kubernetes cluster

* Create a config map with the default settings
* Create a secret witch only contains the credentials needed
* Adjust the provided [cronjob resource](https://github.com/bb-Ricardo/netbox-sync/blob/main/k8s-netbox-sync-cronjob.yaml) to your needs
* Deploy the manifest to your k8s cluster and check the job is running

config example saved as `settings.yaml`
```yaml
netbox:
  host_fqdn: netbox.example.com

source:
  my-vcenter-example:
    type: vmware
    host_fqdn: vcenter.example.com
    permitted_subnets: 172.16.0.0/12, 10.0.0.0/8, 192.168.0.0/16, fd00::/8
    cluster_site_relation: Cluster_NYC = New York, Cluster_FFM.* = Frankfurt, Datacenter_TOKIO/.* = Tokio
```

secrets example saved as `secrets.yaml`
```yaml
netbox:
  api_token: XYZXYZXYZXYZXYZXYZXYZXYZ
source:
  my-vcenter-example:
    username: vcenter-readonly
    password: super-secret
```

Create resource in your k8s cluster
 ```shell
kubectl create configmap netbox-sync-config --from-file=settings.yaml
kubectl create secret generic netbox-sync-secrets --from-file=secrets.yaml
kubectl apply -f k8s-netbox-sync-cronjob.yaml
 ```


# License
>You can check out the full license [here](https://github.com/bb-Ricardo/netbox-sync/blob/main/LICENSE.txt)

This project is licensed under the terms of the **MIT** license.
