#! /usr/bin/env bash

echo "
████████╗███████╗███████╗██╗      █████╗ 
╚══██╔══╝██╔════╝██╔════╝██║     ██╔══██╗
   ██║   █████╗  ███████╗██║     ███████║
   ██║   ██╔══╝  ╚════██║██║     ██╔══██║
   ██║   ███████╗███████║███████╗██║  ██║
   ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝"

echo
echo "===================================="
echo "Installation Script v1.0.0    "
echo "For support contact fheemeyer@ethz.ch"
echo "===================================="
echo 
echo

if ls ~/.ssh/*.pub 2>/dev/null; then
	KEY_FILE=$(ls ~/.ssh/*.pub | head -1)
	echo "public key found in ${KEY_FILE}"
  echo
	echo "Make sure to copy the following and add the key to your GitHub account."
	echo "See https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account"
	echo
	cat ${KEY_FILE}
	echo
	read -p "Press any key to continue"
else
	read -p "No public SSH key was found in ~/.ssh. Should I create one for you? [y]n " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		break
	else
		read -p "Enter your email address: " email
		ssh-keygen -t ed25519 -C "$email" 
		echo "Make sure to copy the following and add the key to your GitHub account."
		echo "See https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account"
		echo
		cat ~/.ssh/id_ed25519.pub

		echo
		read -p "Press any key to continue"
	fi
fi

echo "Starting ssh-agent"
eval `ssh-agent`
echo "Enter the password that you use in your SSH key"
ssh-add

## Instsall ROS noetic
# If ROS is not installed
if [ ! -d "/opt/ros/noetic" ]; then
  read -p "ROS does not seem to be installed to your system. Should I install it for you? [y]n " -n 1 -r
  echo    # (optional) move to a new line
  # If user does not want it to be installed
  if [[ $REPLY =~ ^[Nn]$ ]]; then
		exit 1
	# if user wanths ros to be installed
  else
	sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
    sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
    sudo apt update && sudo apt install -y ros-noetic-desktop-full
    echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
    source /opt/ros/noetic/setup.bash
  fi
# If ROS is installed
else
	# If ROS is installed but not sourced
	if ! grep -q "source /opt/ros/noetic/setup.bash" ~/.bashrc; then
		echo "ROS seems to be installed but not sourced. I will add it to your .bashrc for you."
		echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
  	        source /opt/ros/noetic/setup.bash
	# If ROS is installed and sourced
	else
		echo "ROS is already installed and sourced. Continuing.."
	fi
fi

# Install tools
sudo apt update && sudo apt install -y git python3-catkin-tools python3-osrf-pycommon python3-wstool python3-pip python3-rosdep cython git-lfs swig qtquickcontrols2-5-dev
git lfs install

# Stops the script from stopping due to GitHub not being in the list of known hosts
if ! grep github.com ~/.ssh/known_hosts > /dev/null
then
       echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=" >> ~/.ssh/known_hosts
fi

if [ -d "$HOME/tesla_ws" ]; then
	read -r -p "I found $HOME/tesla_ws. Should I install there? [y]n " -n 1 -r
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		break;
	else	
		ws_dir=$HOME/tesla_ws
	fi
else
		echo
		echo "I will now create the Tesla workspace"
		read -p "Where should the workspace live (default ~/tesla_ws): " ws_dir
		ws_dir=${ws_dir:-"$HOME/tesla_ws"}

		if [ ! -d "$ws_dir" ]; then
			mkdir -p $ws_dir/src/
		else
			echo "Error: directory $ws_dir already exists"
			exit
		fi
fi

# Install pylon 
# Source the bashrc to ensure any previous settings are loaded

# URL to your GitHub repository and the relative path to the .deb file
REPO_SSH_URL="git@github.com:ethz-msrl/ubuntu_installation_guide.git"
SCRIPT_PATH="scripts/pylon/install_pylon.sh"
LOCAL_REPO_DIR="/tmp/ubuntu_installation_guide"

# Clone the repository using SSH
git clone "$REPO_SSH_URL" "$LOCAL_REPO_DIR"

# Execute install script
sudo chmod +x "$LOCAL_REPO_DIR/$SCRIPT_PATH"
"$LOCAL_REPO_DIR/$SCRIPT_PATH"
rm -rf "$LOCAL_REPO_DIR"
echo "Pylon installation complete."
source /opt/pylon5/bin/pylon-setup-env.sh /opt/pylon5


echo
echo "Getting the repo from GitHub"
echo "I will also pull all LFS data"
git clone git@github.com:ethz-msrl/Tesla.git $ws_dir/src/Tesla
cd $ws_dir/src/Tesla
git lfs pull

echo
echo "Installing pre-commit hooks"
pip3 install pre-commit

cd $ws_dir/src/Tesla
pre-commit install

if [ ! -f "$ws_dir/src/.rosinstall" ]; then
	wstool init $ws_dir/src
fi

wstool merge $ws_dir/src/Tesla/dependencies.rosinstall -t $ws_dir/src
wstool update -t $ws_dir/src

wstool merge ~/tesla_ws/src/Tesla_core/dependencies.rosinstall -t $ws_dir/src
wstool update -t $ws_dir/src

wstool merge ~/tesla_ws/src/Navion/dependencies.rosinstall -t $ws_dir/src
wstool update -t $ws_dir/src

cd $ws_dir/src/Tesla_core
pre-commit install

cd $ws_dir/src/Navion
pre-commit install

cd $ws_dir
catkin init
catkin config --extend /opt/ros/$ROS_DISTRO
catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release

if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
fi

rosdep update
rosdep install --from-paths ~/tesla_ws/src --ignore-src -r -y

echo "Adding source $ws_dir/devel/setup.bash to ~/.bashrc"
echo
echo "source $ws_dir/devel/setup.bash" >> ~/.bashrc

read -p "The Tesla workspace is ready to go! Shall I compile some packages for you? [y]n " -n 1 -r
echo    # (optional) move to a new line

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
  echo "Ok... building mag_launch and nav_launch"
  set -e
  catkin build basler_camera --force-cmake
  catkin build mag_launch
  catkin build nav_launch
  set +e
fi

if [[ -f $ws_dir/devel/setup.bash ]]; then
    source $ws_dir/devel/setup.bash
fi

if [[ -f ~/tesla_ws/devel/setup.bash ]]; then    
	read -p "Successfully build the packages. Shall I create desktop shortcuts for the Navion and the Cmag fot you? [y]n " -n 1 -r
	if [[ ! $REPLY =~ ^[Nn]$ ]]; then
		# Set the path to the scripts
		TESLA_DESKTOP_PATH=~/tesla_ws/src/Tesla/desktop/install_default_desktop_files.sh
		NAVION_DESKTOP_PATH=~/tesla_ws/src/Navion/desktop/install_default_desktop_files.sh

		# Change the mode to executable
		chmod +x $TESLA_DESKTOP_PATH
		chmod +x $NAVION_DESKTOP_PATH

		# Execute the scripts
		$TESLA_DESKTOP_PATH
		$NAVION_DESKTOP_PATH
		
		echo "Great! You can now find the shortcuts in your application menu."
		echo "You can create more shortcuts by executing the scripts in the desktop folders of Tesla and Navion."
	fi


fi

echo
echo "Done installing Tesla. Have fun!"
