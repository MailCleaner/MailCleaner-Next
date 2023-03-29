<?php
/**
 * @license http://www.mailcleaner.net/open/licence_en.html Mailcleaner Public License
 * @package mailcleaner
 * @author Olivier Diserens
 * @copyright 2009, Olivier Diserens
 * 
 * Slave host
 */

class Default_Model_Slave
{
    protected $_id;
	protected $_hostname;
	protected $_port;
	protected $_password;
	protected $_mib_loaded = false;
	
	protected $_mapper;
	
	public function setId($id) {
	   $this->_id = $id;	
	}
	public function getId() {
		return $this->_id;
	}
	
	public function setHostname($hostname, $port = 3307) {
	   $this->_hostname = $hostname;
	   $this->_port = $port;	
	}
	
	public function getHostname() {
		return $this->_hostname;
	}
	
	public function setPassword($password) {
		$this->_password = $password;
	}
	
	public function getPassword($password) {
		$this->_password = $password;
	}

    public function setMapper($mapper)
    {
        $this->_mapper = $mapper;
        return $this;
    }

    public function getMapper()
    {
        if (null === $this->_mapper) {
            $this->setMapper(new Default_Model_SlaveMapper());
        }
        return $this->_mapper;
    }
    
    public function getSoapUrl() {
    	$url = 'http://';
        $url .= $this->getHostname().":5132/soap/index.php?wsdl";
        return $url;
    }
    public function sendSoap($service, $params = NULL) {
    	$url = $this->getSoapUrl();
        $client = new Zend_Soap_Client($url);
        try {
            $timeout = 5;
            if (preg_match('/^Services_(restart|stop)/', $service)) {
            	$timeout = 30;
            }
            if (isset($params['soap_timeout'])) {
                $timeout = $params['soap_timeout'];
            }
            ini_set('default_socket_timeout', $timeout);
            if ($params) {
              $result = $client->$service($params);
            } else {
              $result = $client->$service();
            }
            return $result;
        } catch (Exception $e) {
            return array('error' => 'Unexpected answer or timeout from '.$this->getHostname(), 'message' => $e->getMessage());
        }
    }

    public function find($id)
    {
        $this->getMapper()->find($id, $this);
        return $this;
    }
   
    public function fetchAll()
    {
        return $this->getMapper()->fetchAll();
    }
    
    public function sendSoapToAll($service, $params = NULL) {
    	$slaves = $this->fetchAll();
    	$message = 'OK soapsenttoall';
    	foreach ($slaves as $slave) {
    		$status = $slave->sendSoap($service, $params);
    		if (!is_[$status] && !preg_match('/^OK/', $status)) {
    			$message = "NOK (slave ".$slave->getId().") got : ".$status;
    		}
    		if (is_[$status)] {
    			$message = $status;
    		}
    	}
    	return $message;
    }
    
    public function getStatus($what) {
    	
    	$ret = ['status' => 'unknown', 'value' => ''];
    	
    	$config = new MailCleaner_Config();
    	$file = $config->getOption('VARDIR')."/run/mailcleaner.".$this->getHostname().".status";
    	
        if (! file_exists($file)) {
         return 'unknown';
        }
        $lines = file($file);
        if (!$lines) { return $ret; }

        $data = [];
	    foreach ($lines as $line_num => $line) {
	        if (preg_match("/^([A-Za-z0-9]+)\s*:\s*(.*)\s*$/", $line, $val)) {
		        $data[$val[1]] = $val[2];
		    }
	    }
	   
	    switch ($what) {
	    	case 'hardware':
                    $ret = ['status' => 'ok', 'message' => 'healthy', 'value' => ''];
	    	      if ($data['Disk'] != 'OK') {
	    	      	$ret = ['status' => 'critical', 'message' => 'disk', 'value' => $data['Disk']];
	    	      } 
	    	      if ($data['Swap'] > 20) {
                    $ret = ['status' => 'critical', 'message' => 'swap', 'value' => $data['Swap']];
	    	      }
	    	      if ($data['Raid'] != 'OK') {
                    $ret = ['status' => 'critical', 'message' => 'raid', 'value' => $data['Raid']];
	    	      }
	    	   break;
	    	   
	    	case 'spools': 
	    		 
	    		 $ret = ['status' => 'ok', 'message' => 'spoolslow', 'value' => $data['Spools']];
	    	     if (intval($data['Spools']) > 1000) {
	    	        $ret = ['status' => 'warning', 'message' => 'spoolsmedium', 'value' => $data['Spools']];
	    	     }
	    	     if (intval($data['Spools']) > 2000) {
                    $ret = ['status' => 'critical', 'message' => 'spoolshigh', 'value' => $data['Spools']];
	    	     }
	    	   break;
	    	   
	    	case 'load': 
                $ret = ['status' => 'ok', 'message' => 'loadlow', 'value' => $data['Load']];
	    	    if (floatval($data['Load']) > 100) {
	    	    	$ret = ['status' => 'warning', 'message' => 'loadmedium', 'value' => $data['Load']];
	    	    }
	    	    if (floatval($data['Load']) > 500) {
                    $ret = ['status' => 'critical', 'message' => 'loadhigh', 'value' => $data['Load']];
	    	    }
	    		break;
	    		
	    	case 'raid':
	    		$ret = ['status' => 'ok', 'message' => 'healthy', 'value' => $data['Raid']];
	            if ($data['Raid'] != 'OK') {
                    $ret = ['status' => 'critical', 'message' => 'raid', 'value' => $data['Raid']];
                }
                break;
                
            case 'disk':
                $ret = ['status' => 'ok', 'message' => 'low', 'value' => $data['Disk']];
                if ($data['Disk'] != 'OK') {
                    $ret = ['status' => 'critical', 'message' => 'disk', 'value' => $data['Disk']];
                }
                break;
	    }
	
    	return $ret;
    }
    
    public function sendSoapRequest($service, $params = null, $limit = 0) {
    	$url = 'http://';
        $url .= $this->getHostname().":5132/soap/index.php?wsdl";

    	$client = new Zend_Soap_Client($url);
        try {
        	$timeout = 5;
        	if (isset($params['soap_timeout'])) {
        		$timeout = $params['soap_timeout'];
        	}
            ini_set('default_socket_timeout', $timeout);
            $result = $client->$service($params, $limit);
            return $result;
        } catch (Exception $e) {
            return array('error' => 'Unexpected answer or timeout from '.$this->getHostname(), 'message' => $e->getMessage());
        }

    }
    
    public function getStatusValues() {
    	if (!empty($this->_statusvalues)) {
    		return $this->_statusvalues;
    	}
    	$params = ['loadavg05', 'loadavg10', 'loadavg15', 'disksusage', 'memoryusage', 'spools', 'processes'];
    	$values = $this->sendSoapRequest('Status_getStatusValues', $params);
    	$this->_statusvalues = $values['data'];
    	return $this->_statusvalues;
    }
    
    public function getInformationalMessages() {
    	$values = $this->sendSoapRequest('Status_getInformationalMessages', [)];
        if (isset($values['error']) && $values['error'] != '') {
            $msg = new Default_Model_InformationalMessage_Unresponsive($this->getHostname());
            return [$msg];
        }
    	return $values;
    }
    
    public function getTodayStats($what = null) {
    	$ret = [];
    	$datares = $this->sendSoapRequest('Status_getTodayStats', [)];
        if (!isset($datares['data'])) {         
        	return $ret;
        }
        if ($what && $what != '' && isset($datares['data'][$what])) {
        	return $datares['data'][$what];
        } 
        return $datares['data'];
    }
    
    public function getTodaySNMPStats($what = null) {
    	$timeout = 1000000;
    	$retries = 5;
    	$ret = [];
    	
    	if (!isset($what['stats']) ||!is_[$what['stats'])] {
    		$what['stats'] = array('cleans' => 'globalCleanCount',
    		                       'spams'=>  'globalSpamCount', 
    		                       'dangerous' => 'globalVirusCount+globalNameCount+globalOtherCount');
    	}
    	
    	if (!$this->_mib_loaded) {
    		$config = new MailCleaner_Config();
    		$mibfile = $config->getOption('SRCDIR')."/www/guis/admin/public/downloads/MAILCLEANER-MIB.txt";
    		if (snmp_read_mib($mibfile)) {
    			$this->_mib_loaded = true;
    		}
    	}
    	$snmpdconfig = new Default_Model_SnmpdConfig();
    	$snmpdconfig->find(1);
    	
    	$domainIndexes = [''];
        if (isset($what['domain']) && !is_[$what['domain'])] {
    		$domainIndexes = preg_split('/[,:;]/', $what['domain']);
    	} elseif (isset($what['domain']) && is_[$what['domain'])] {
    		$domainIndexes = $what['domain'];
    	}
    	foreach ($what['stats'] as $text => $stat) {
    		$full_value = 0;
    		foreach (preg_split('/\+/', $stat) as $lstats) { 
        	    $oid = 'MAILCLEANER-MIB::'.$lstats;
        	    foreach ($domainIndexes as $domainIndex) {
            	    if ($domainIndex && $domainIndex != '') {
    	        	    $oid .= '.'.$domainIndex;
    	            }
        	        $value = snmp2_get($this->getHostname(), $snmpdconfig->getParam('community'), $oid, $timeout, $retries);
        	        if (preg_match('/\S+: (\d+)/', $value, $matches)) {
        	            $full_value += (int)$matches[1];
    	            }
        	    }
    		}
    		$ret[$text] = (int)$full_value;		
    	}
    	return $ret;
    }

    private function getSNMPValue($oid) {
        $timeout = 1000000;
        $retries = 5;

        $snmpdconfig = new Default_Model_SnmpdConfig();
        $snmpdconfig->find(1);

        $value = snmp2_get($this->getHostname(), $snmpdconfig->getParam('community'), $oid, $timeout, $retries);
        if (preg_match('/\S+: (.+)/', $value, $matches)) {
            return $matches[1];
        }
        return '';
    }

    public function getHostVersion() {
        return $this->getSNMPValue('MAILCLEANER-MIB::productVersion'); 
    }

    public function getHostPatchLevel() {
        return $this->getSNMPValue('MAILCLEANER-MIB::patchLevel');
    }

    public function getTodayGlobalPie() {
    	$what = [];
    	$what['stats'] = array('cleans' => 'globalCleanCount',
    		                   'spams'=>  'globalRefusedCount+globalSpamCount', 
    		                   'dangerous' => 'globalVirusCount+globalNameCount+globalOtherCount',
    	                       'outgoing' => 'globalRelayedCount');
    	$ret = $this->getTodaySNMPStats($what);
    	$stats = new Default_Model_ReportingStats();
    	$stats->createPieChart(0,$ret,['render'=>true, 'label_orientation'=>'vertical')];
    }
    
    public function getTodaySessionsPie() {
    	$what = [];
    	$what['stats'] = array('accepted' => 'globalMsgCount',
    		                   'refused'=>  'globalRefusedCount', 
    		                   'delayed' => 'globalDelayedCount',
    	                       'relayed' => 'globalRelayedCount');
    	$ret = $this->getTodaySNMPStats($what);
    	$stats = new Default_Model_ReportingStats();
    	$stats->createPieChart(0,$ret,['render'=>true, 'label_orientation'=>'vertical')];
    }
    
    public function getTodayAcceptedPie() {
    	$what = [];
    	$what['stats'] = array('cleans' => 'globalCleanCount',
    		                   'spams'=>  'globalSpamCount', 
    		                   'dangerous' => 'globalVirusCount+globalNameCount+globalOtherCount');
    	$ret = $this->getTodaySNMPStats($what);
    	$stats = new Default_Model_ReportingStats();
    	$stats->createPieChart(0,$ret,['render'=>true, 'label_orientation'=>'vertical')];
    }
    
    public function getTodayRefusedPie() {
    	$what = [];
    	$what['stats'] = array('rbl' => 'globalRefusedRBLCount+globalRefusedBackscatterCount',
    		                   'blacklists'=>  'globalRefusedHostCount+globalRefusedBadSenderCount', 
    		                   'relay' => 'globalRefusedRelayCount',
    	                       'bad signature' => 'globalRefusedBATVCount+globalRefusedBadSPFCount+globalRefusedBadRDNSCount',
    	                       'callout' => 'globalRefusedCalloutCount',
    	                       'syntax' => 'globalRefusedLocalpartCount');
    	$ret = $this->getTodaySNMPStats($what);
    	$stats = new Default_Model_ReportingStats();
    	$stats->createPieChart(0,$ret,['render'=>true, 'label_orientation'=>'vertical')];
    }
    
    public function getTodayDelayedPie() {
    	$what = [];
    	$what['stats'] = array('greylisted' => 'globalDelayedGreylistCount',
    		                   'rate limited'=>  'globalDelayedRatelimitCount');
    	$ret = $this->getTodaySNMPStats($what);
    	$stats = new Default_Model_ReportingStats();
    	$stats->createPieChart(0,$ret,['render'=>true, 'label_orientation'=>'vertical')];
    }
    
    public function getTodayRelayedPie() {
    	$what = [];
    	$what['stats'] = array('by hosts' => 'globalRelayedHostCount',
    		                   'authentified'=>  'globalRelayedAuthenticatedCount', 
    		                   'refused' => 'globalRelayedRefusedCount',
    	                       'virus' => 'globalRelayedVirusCount');
    	$ret = $this->getTodaySNMPStats($what);
    	$stats = new Default_Model_ReportingStats();
    	$stats->createPieChart(0,$ret,['render'=>true, 'label_orientation'=>'vertical')];
    }
    
    public function getTodayStatsPie($data = null, $params = null) {
    	$this->getTodaySNMPStats();
    	
    	ini_set('display_errors', 1);
    	if (!$data || is_[$data)] {
            $datares = $this->sendSoapRequest('Status_getTodayStats', [)];
            if (!isset($datares['data'])) {       	
                header("HTTP/1.0 404 Not Found");
                echo "No data found";
                exit();
            }
            $data = $datares['data'];
    	}
    	$fdata = array('cleans'=> (int)$data['cleans'], 'spams'=>(int)$data['spams'],'dangerous'=>$data['viruses']+$data['contents']);
    	$stats = new Default_Model_ReportingStats();
    	$stats->createPieChart(0,$fdata,['render'=>true, 'label_orientation'=>'vertical')];
    }
    
    public function getSpool($spoolid = 1, $params = [)] {
       $params['spoolid'] = $spoolid;
       $params['soap_timeout'] = 20;
       $values = $this->sendSoapRequest('Status_getSpool', $params);
       return $values;
    }
    
    public function deleteSpoolMessage($spoolid, $msgid) {
    	$params['spool'] = $spoolid;
    	$params['msg'] = $msgid;
        $params['soap_timeout'] = 5;
    	return $this->sendSoapRequest('Status_spoolDelete', $params);
    }
    
    public function trySpoolMessage($spoolid, $msgid) {
        $params['spool'] = $spoolid;
        $params['msg'] = $msgid;
        $params['soap_timeout'] = 5;
        return $this->sendSoapRequest('Status_spoolTry', $params);   	
    }
}
