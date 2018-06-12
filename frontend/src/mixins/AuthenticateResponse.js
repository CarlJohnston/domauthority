import STATUS from 'configs/Status';

/*
 * Helper for authentication API Responses
 */
class AuthenticateResponse {
  constructor(data) {
    this.set(data);

    this.defaults = {
      success: 'Success.',
    };
  }

  /*
   * @param data {Object}  a response object with the following properties
   *                        {
   *                          body: {Object},
   *                          [headers: {Headers}],
   *                        }
   */
  set(data) {
    if (data && typeof data === 'object') {
      this.data = data;

      if (!('body' in data)) {
        data.body = {};
      }

      if (!('headers' in data)) {
        data.headers = new Headers();
      }
    } else {
      this.data = {
        body: {},
        headers: new Headers(),
      };
    }
  }

  /*
   * @returns {Array}  array of messages where each message is the key with a
   *                   status type of type STATUS as value
   *                    {
   *                      {String}: {String},
   *                    }
   */
  getMessages() {
    var messages = {};

    if (this.data.body &&
        typeof this.data.body === 'object' &&
        'errors' in this.data.body) {
      if (typeof this.data.body.errors === 'object') {
        if ('full_messages' in this.data.body.errors) {
          this.data.body.errors.full_messages.forEach((error) => {
            messages[error] = STATUS.error;
          });
        } else {
          Object.entries(this.data.body.errors).forEach(([key, error]) => {
            messages[error] = STATUS.error;
          });
        }
      } else {
        messages[this.data.body.errors] = STATUS.error;
      }
    } else {
      messages[this.defaults.success] = STATUS.success;
    }

    return messages;
  }
}

export default AuthenticateResponse;
