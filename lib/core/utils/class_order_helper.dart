int getClassOrder(String className) {
  switch (className.trim()) {
    case 'LKG':
      return 1;

    case 'UKG':
      return 2;

    case 'Class 1':
      return 3;

    case 'Class 2':
      return 4;

    case 'Class 3':
      return 5;

    case 'Class 4':
      return 6;

    case 'Class 5':
      return 7;

    case 'Class 6':
      return 8;

    case 'Class 7':
      return 9;

    case 'Class 8':
      return 10;

    case 'Class 9':
      return 11;

    case 'Class 10':
      return 12;

    case 'I-PU':
      return 13;

    case 'II-PU':
      return 14;

    default:
      return 999;
  }
}