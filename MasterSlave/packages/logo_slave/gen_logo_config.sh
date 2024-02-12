#!/bin/bash

hub_name="slave"
host="192.168.100.208"
port="502"
qnum="4"
qoft="16"
scan_interval="5"

#==================================

config="modbus.yaml"
truncate --size 0 ${config}

cat >> ${config} << EOF
logo_modbus_${hub_name}:
  modbus:
    name: ${hub_name}
    type: tcp
    host: ${host}
    port: ${port}
    switches:
EOF

for num in $(seq 1 $qnum); do
cat >> ${config} << EOF
      - name: v$((num + qoft))_on
        unique_id: v$((num + qoft))_on
        write_type: coil
        address: $((num * 8 + 1))
      - name: v$((num + qoft))_off
        unique_id: v$((num + qoft))_off
        write_type: coil
        address: $((num * 8 + 2))
EOF
done

cat >> ${config} << EOF
    binary_sensors:
EOF

for num in $(seq 1 $qnum); do
cat >> ${config} << EOF
      - name: q$((num + qoft))s
        unique_id: q$((num + qoft))s
        input_type: coil
        address: $((num + 8191))
        scan_interval: ${scan_interval}
EOF
done

#==================================

config="switches.yaml"
truncate --size 0 ${config}

cat >> ${config} << EOF
logo_switches_${hub_name}:
  switch:
    - platform: template
      switches:
EOF

for num in $(seq 1 $qnum); do
cat >> ${config} << EOF
        q$((num + qoft)):
          unique_id: q$((num + qoft))
          value_template: "{{ is_state('binary_sensor.q$((num + qoft))s', 'on') }}"
EOF
  for action in on off; do
cat >> ${config} << EOF
          turn_${action}:
            - service: switch.turn_on
              target:
                entity_id: switch.v$((num + qoft))_${action}
            - delay:
                milliseconds: 50
            - service: switch.turn_off
              target:
                entity_id: switch.v$((num + qoft))_${action}
            - service: python_script.set_state
              data:
                entity_id: binary_sensor.q$((num + qoft))s
                state: '${action}'
EOF
  done
done
