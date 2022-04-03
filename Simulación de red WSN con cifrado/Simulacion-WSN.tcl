# This script is created by NSG2 beta1
# <http://wushoupong.googlepages.com/nsg>

#===================================
#     Simulation parameters setup
#===================================
Antenna/OmniAntenna set Gt_ 1              ;#Transmit antenna gain
set val(chan)   Channel/WirelessChannel    ;# channel type
set val(prop)   Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)  Phy/WirelessPhy            ;# network interface type
set val(mac)    Mac/802_11                 ;# MAC type
set val(ifq)    Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)     LL                         ;# link layer type
set val(ant)    Antenna/OmniAntenna        ;# antenna model
set val(ifqlen) 50                         ;# max packet in ifq
set val(nn)     5                          ;# number of mobilenodes
set val(rp)     DSDV                       ;# routing protocol
set val(x)      786                      ;# X dimension of topography
set val(y)      685                      ;# Y dimension of topography
set val(stop)   10.0                         ;# time of simulation end

#===================================
#        Initialization        
#===================================
#Create a ns simulator
set ns [new Simulator]

#Setup topography object
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)

#Open the NS trace file
set tracefile [open Simulacion-WSN.tr w]
$ns trace-all $tracefile

#Open the NAM trace file
set namfile [open Simulacion-WSN.nam w]
$ns namtrace-all $namfile
$ns namtrace-all-wireless $namfile $val(x) $val(y)
set chan [new $val(chan)];#Create wireless channel

#===================================
#     Mobile node parameter setup
#===================================
$ns node-config -adhocRouting  $val(rp) \
                -llType        $val(ll) \
                -macType       $val(mac) \
                -ifqType       $val(ifq) \
                -ifqLen        $val(ifqlen) \
                -antType       $val(ant) \
                -propType      $val(prop) \
                -phyType       $val(netif) \
                -channel       $chan \
                -topoInstance  $topo \
                -agentTrace    ON \
                -routerTrace   ON \
                -macTrace      ON \
                -movementTrace ON


## **** Encrypted Connection ****
## Communication with Encryption

# Procedure to Encrypt
proc encrypt {s {n 3}} {
    set r {}
    binary scan $s c* d
    foreach {c} $d {
        append r [format %c [expr {
                        (($c ^ 0x40) & 0x5F) < 27 ? 
                        (((($c ^ 0x40) & 0x5F) + $n - 1) % 26 + 1) | ($c & 0xe0)
                        : $c
                    }]]
    }
    return $r
}

# Procedure to Decrypt
proc decrypt {s {n 3}} {
    set n [expr {abs($n - 26)}]
     return [encrypt $s $n]
}

# UDP Agent procedure to Process Recieved Data
Agent/UDP instproc process_data {size data} {
    global ns
    $self instvar node_
    $ns trace-annotate "Message received by [$node_ node-addr] :  {$data}"
    set dec_message [decrypt $data]
    $ns trace-annotate "Decoded Message recieved by [$node_ node-addr]: {$dec_message}"
}

# Procedure to send Data
proc send_message {node agent message} {
    global ns
    $ns trace-annotate "Message to be sent by [$node node-addr] : {$message}"
    set enc_message [encrypt $message]
    $ns trace-annotate "Encoded Message sent by [$node node-addr] : {$enc_message}"
    eval {$agent} send 999 {$enc_message}
}


#===================================
#        Nodes Definition        
#===================================
#Create 5 nodes
set n0 [$ns node]
$n0 set X_ 440
$n0 set Y_ 456
$n0 set Z_ 0.0
$ns initial_node_pos $n0 20
set n1 [$ns node]
$n1 set X_ 272
$n1 set Y_ 585
$n1 set Z_ 0.0
$ns initial_node_pos $n1 20
set n2 [$ns node]
$n2 set X_ 235
$n2 set Y_ 320
$n2 set Z_ 0.0
$ns initial_node_pos $n2 20
set n3 [$ns node]
$n3 set X_ 540
$n3 set Y_ 239
$n3 set Z_ 0.0
$ns initial_node_pos $n3 20
set n4 [$ns node]
$n4 set X_ 686
$n4 set Y_ 470
$n4 set Z_ 0.0
$ns initial_node_pos $n4 20

#===================================
#        Agents Definition        
#===================================
#Setup a TCP connection
set tcp0 [new Agent/TCP]
$ns attach-agent $n1 $tcp0
set sink4 [new Agent/TCPSink]
$ns attach-agent $n0 $sink4
$ns connect $tcp0 $sink4
$tcp0 set packetSize_ 1500

#Setup a TCP connection
set tcp1 [new Agent/TCP]
$ns attach-agent $n2 $tcp1
set sink8 [new Agent/TCPSink]
$ns attach-agent $n0 $sink8
$ns connect $tcp1 $sink8
$tcp1 set packetSize_ 1500

#Setup a TCP connection
set tcp2 [new Agent/TCP]
$ns attach-agent $n3 $tcp2
set sink9 [new Agent/TCPSink]
$ns attach-agent $n0 $sink9
$ns connect $tcp2 $sink9
$tcp2 set packetSize_ 1500

#Setup a TCP connection
set tcp3 [new Agent/TCP]
$ns attach-agent $n4 $tcp3
set sink10 [new Agent/TCPSink]
$ns attach-agent $n0 $sink10
$ns connect $tcp3 $sink10
$tcp3 set packetSize_ 1500


#===================================
#        Applications Definition        
#===================================
#Setup a FTP Application over TCP connection
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0
$ns at 1.0 "$ftp0 start"
$ns at 4.0 "$ftp0 stop"

#Setup a FTP Application over TCP connection
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ns at 1.0 "$ftp1 start"
$ns at 4.0 "$ftp1 stop"

#Setup a FTP Application over TCP connection
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ns at 1.0 "$ftp2 start"
$ns at 4.0 "$ftp2 stop"

#Setup a FTP Application over TCP connection
set ftp3 [new Application/FTP]
$ftp3 attach-agent $tcp3
$ns at 1.0 "$ftp3 start"
$ns at 4.0 "$ftp3 stop"


# Agent Creation
set enc_udp0 [new Agent/UDP]
$ns attach-agent $n0 $enc_udp0
$enc_udp0 set fid_ 0

set enc_udp1 [new Agent/UDP]
$ns attach-agent $n1 $enc_udp1
$enc_udp1 set fid_ 1
$ns connect $enc_udp0 $enc_udp1

# Start Traffic
$ns at 2.1 "$ns trace-annotate {Starting Encrypted Communication...}"
$ns at 2.1 "send_message $n0 $enc_udp0 {Send me the password}"
$ns at 2.3 "send_message $n1 $enc_udp1 {Password is SeGuRiDaDeNrEdEs1}"
$ns at 2.1 "send_message $n0 $enc_udp0 {Send me the password}"
$ns at 2.3 "send_message $n2 $enc_udp1 {Password is SeGuRiDaDeNrEdEs2}"
$ns at 2.1 "send_message $n0 $enc_udp0 {Send me the password}"
$ns at 2.3 "send_message $n3 $enc_udp1 {Password is SeGuRiDaDeNrEdEs3}"
$ns at 2.1 "send_message $n0 $enc_udp0 {Send me the password}"
$ns at 2.3 "send_message $n4 $enc_udp1 {Password is SeGuRiDaDeNrEdEs4}"
$ns at 2.5 "$ns trace-annotate {Encrypted Communication Stopped...}"

#===================================
#        Termination        
#===================================
#Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile
    close $namfile
    exec nam Simulacion-WSN.nam &
    exit 0
}
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "\$n$i reset"
}
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
#$ns at $val(stop) "finish"
$ns at $val(stop) "puts \"done\" ; $ns halt"
#$ns run


$ns at 2.8 "finish"
$ns run


