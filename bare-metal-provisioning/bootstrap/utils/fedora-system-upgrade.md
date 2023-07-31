## Optional: Upgrade your system

```shell
# Upgrade the system
LATEST_RELEASE=38
dnf install dnf-plugin-system-upgrade -y
dnf system-upgrade download --releasever="${LATEST_RELEASE}" -y
dnf system-upgrade reboot -y
```

```shell
# Post upgrade
dnf system-upgrade clean -y
dnf install rpmconf remove-retired-packages -y
#rpmconf -a
#remove-retired-packages
dnf autoremove -y

# Cleanup old kernels
{
  old_kernels=($(dnf repoquery --installonly --latest-limit=-1 -q))
  if [ "${#old_kernels[@]}" -eq 0 ]; then
      echo "No old kernels found"
  fi
  
  if ! dnf remove "${old_kernels[@]}" --skip-broken; then
      echo "Failed to remove old kernels"
  else
    echo "Removed old kernels"
  fi
}

# Other cleanup task
rpm --rebuilddb -y
dnf distro-sync --allowerasing -y
fixfiles -B onboot

# upgrade packages
dnf upgrade --refresh -y
reboot
```