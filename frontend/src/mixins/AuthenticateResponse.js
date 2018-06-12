import STATUS from 'configs/Status';

/*
 * Helper for authentication API Responses
 */
class AuthenticateResponse {
  constructor(data) {
    this.setData(data);
  }

  setData(data) {
    if (data && typeof data === 'object') {
      this.data = data;
    } else {
      this.data = {};
    }
  }

  /*
   * @returns {Array} array of error messages
   */
  getErrors() {
    var errors = [];

    if ('errors' in this.data) {
      if (typeof this.data.errors === 'object') {
        if ('full_messages' in this.data.errors) {
          this.data.errors.full_messages.forEach((error) => {
            errors.push(error);
          });
        } else {
          Object.entries(this.data.errors).forEach((error) => {
            errors.push(error[1]);
          });
        }
      } else {
        errors.push(this.data.errors);
      }
    }

    return errors;
  }

  /*
   * @returns {String} response status
   */
  getStatus() {
    var status = '';

    if ('errors' in this.data &&
       this.data.errors.length !== 0) {
      status = STATUS.error;
    } else {
      status = STATUS.success;
    }

    return status;
  }

  /*
   * @returns {String} response data
   */
  getData() {
    return this.data.data || {};
  }
}

export default AuthenticateResponse;