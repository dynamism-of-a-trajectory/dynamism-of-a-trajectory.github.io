#!/bin/bash
# agent_judges.py needs pyyaml + numpy (system python3 has them) and calls the scorers with their own envs.
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
cd $RD && python3 agent_judges.py --task "$1" --traj "$2" --dir "$3"
