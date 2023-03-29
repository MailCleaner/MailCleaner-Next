<?php
/**
 * @license http://www.mailcleaner.net/open/licence_en.html Mailcleaner Public License
 * @package mailcleaner
 * @author Olivier Diserens
 * @copyright 2009, Olivier Diserens
 * 
 * Interface login form
 */

class Default_Form_Login extends Zend_Form
{
	public function init()
	{
		$this->setMethod('post');
			
		$t = Zend_Registry::get('translate');
			
		$usernameField = $this->createElement( 'text', 'username', array(
            'label'      => $t->_('Username')." :",
            'required'   => true,
            'filters'    => ['StringTrim'],
		));
#		$usernameField->addValidator(new Zend_Validate_Alnum());

		$usernameField->setDecorators(array(
                              'ViewHelper',
                              'Errors',
		                      array(['data' => 'HtmlTag'], ['tag' => 'td', 'class' => 'element')],
		                      array('Label', ['tag' => 'td')],
		                      array(['row' => 'HtmlTag'], ['tag' => 'tr')],
		                 ));
        $usernameField->removeDecorator('Errors');
		$this->addElement($usernameField);

		$passwordField = $this->createElement('password', 'password', array(
             'label'      => $t->_('Password')." :",
             'required'   => true,
             'filters'    => ['StringTrim'],
             'validators' => array(array('validator' => 'StringLength', 'options' => [0, 100))],
             'allowEmpty' => true,
		));
		$passwordField->setDecorators(array(
                              'ViewHelper',
                              'Errors',
		                      array(['data' => 'HtmlTag'], ['tag' => 'td', 'class' => 'element')],
		                      array('Label', ['tag' => 'td')],
		                      array(['row' => 'HtmlTag'], ['tag' => 'tr')],
		                 ));
        $passwordField->removeDecorator('Errors');
		$this->addElement($passwordField);

		$loginButton = $this->createElement('submit', 'submit', ['label'      => 'login')];
		$loginButton->setDecorators(array(
               'ViewHelper',
               array(['data' => 'HtmlTag'], ['tag' => 'td', 'class' => 'element')],
               array(['label' => 'HtmlTag'], ['tag' => 'td', 'placement' => 'prepend')],
               array(['row' => 'HtmlTag'], ['tag' => 'tr')],
           ));
		$this->addElement($loginButton);
		
		$this->setDecorators(array(
               'FormElements',
               array('HtmlTag', ['tag' => 'table')],
               'Form',
           ));

	}

}
