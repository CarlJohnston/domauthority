import React, { Component } from 'react';
import { Route } from 'react-router-dom';

import Footer from 'components/Footer/Footer';
import Header from 'components/Header/Header';
import Login from 'components/NewLogin/NewLogin';
import Register from 'components/Register/Register';
import Forgot from 'components/Forgot/Forgot';
import Confirmed from 'components/Confirmed/Confirmed';
import Home from 'components/Home/Home';
import Profile from 'components/Profile/Profile';
import Settings from 'components/Settings/Settings';
import Analyze from 'components/Analyze/Analyze';
import Sites from 'components/Sites/Sites';

import withCurrentUser from 'components/hocs/withCurrentUser';

class Layout extends Component {
  render() {
    return (
      <div>
        <Header {...this.props} />

        <Route exact path='/' component={Home} />

        <div className='grid-container'>
          <Route path='/login' component={Login} />
          <Route path='/register' component={Register} />

          <Route path='/password/forgot' component={Forgot} />
          <Route path='/auth/confirmed' component={Confirmed} />

          <Route path='/users/:id' component={Profile} />
          <Route path='/settings' component={Settings} />

          <Route path='/sites' component={Sites} />
          <Route path='/analyze' component={Analyze} />
        </div>

        <Footer {...this.props }/>
      </div>
    );
  }
}

export default withCurrentUser(Layout);
