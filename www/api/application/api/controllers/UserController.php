<?php
/**
 * @license http://www.mailcleaner.net/open/licence_en.html Mailcleaner Public License
 * @package mailcleaner
 * @author Olivier Diserens
 * @copyright 2009, Olivier Diserens
 *
 * index page controller
 */

class UserController extends Zend_Controller_Action
{

	public function init()
	{
		$this->_helper->layout->disableLayout();
		$this->_helper->viewRenderer->setNoRender(true);
	}

	public function addAction()
	{
		$request = $this->getRequest();
		$api = new Api_Model_UserAPI();
		$api->add($request->getParams());
	}
	
    public function editAction()
    {
        $request = $this->getRequest();
        $api = new Api_Model_UserAPI();
        $api->edit($request->getParams());
    }
    
    public function existsAction()
    {
        $request = $this->getRequest();
        $api = new Api_Model_UserAPI();
        $api->exists($request->getParams());
    }
    
    public function deleteAction()
    {
        $request = $this->getRequest();
        $api = new Api_Model_UserAPI();
        $api->delete($request->getParams());
    }
    
    public function showAction()
    {
        $request = $this->getRequest();
        $api = new Api_Model_UserAPI();
        $api->show($request->getParams());
    }

    public function listAction()
    {
    	$request = $this->getRequest();
        $api = new Api_Model_UserAPI();
    	$api->userList($request->getParams());
    }
    
    public function listAddresses()
    {
    	$request = $this->getRequest();
        $api = new Api_Model_UserAPI();
    	$api->listAddresses($request->getParams());
    }
}