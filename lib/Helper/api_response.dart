class APIResponse<T> { // Build #1.0.8, Naveen added
  Status status;

  T? data;

  String? message;

  APIResponse.loading(this.message) : status = Status.LOADING;

  APIResponse.completed(this.data) : status = Status.COMPLETED;

  APIResponse.loadingData(this.data) : status = Status.LOADING;

  APIResponse.error(this.message) : status = Status.ERROR;

  @override
  String toString() {
    return "Status : $status \n Message : $message \n Data : $data";
  }
}

enum Status { LOADING, COMPLETED, ERROR }