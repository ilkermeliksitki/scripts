#!/bin/bash

# take a screenshot using flameshot and copy it to the clipboard
flameshot gui --clipboard

# return to default mode after taking a screenshot in i3
i3-msg mode "default"

