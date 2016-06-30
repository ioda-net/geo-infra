(function (angular) {
    'use strict';

    var module = angular.module('angular-bind-html-compile', []);

    module.directive('bindHtmlCompile', ['$compile', function ($compile) {
        return {
            restrict: 'A',
            link: function (scope, element, attrs) {
                scope.$watch(function () {
                    return scope.$eval(attrs.bindHtmlCompile);
                }, function (value) {
                    // In case value is a TrustedValueHolderType, sometimes it
                    // needs to be explicitly called into a string in order to
                    // get the HTML string.
                    element.html(value && value.toString());
                    // If scope is provided use it, otherwise use parent scope
                    var compileScope = scope;
                    if (attrs.bindHtmlScope) {
                        compileScope = scope.$eval(attrs.bindHtmlScope);
                    }
                    $compile(element.contents())(compileScope);
                });
            }
        };
    }]);
}(window.angular));


(function () {
  angular.module('helpApp', ['angular-bind-html-compile']);
})();


(function () {
  'use strict';

  angular.module('helpApp').factory('helpService', helpService);

  function helpService($http, $q, $sce) {
    var help = {};
    var langs_promise = $q.defer();

    init();

    return {
      getText: getText,
      getLangs: getLangs
    };

    function init() {
      $http.get('/help/langs.json').success(function (data) {
        langs_promise.resolve(data);
      }).error(function () {
        langs_promise.resolve(['fr', 'de']);
      });
    }

    function getText(lang) {
      if (!help[lang]) {
        var deferred = $q.defer();
        var url = '/help/texts/{lang}.json'.replace('{lang}', lang);
        $http.get(url)
                .success(function (data) {
                  var currentHelp = {
                    texts: [],
                    idToIndex: {}
                  };
                  data.forEach(function (row, index) {
                    currentHelp.texts.push({
                      id: row.id,
                      title: $sce.trustAsHtml(row.title),
                      content: row.content,
                      image: row.image,
                      isTitle: row.isTitle
                    });
                    currentHelp.idToIndex[row.id] = index;
                  });

                  deferred.resolve(currentHelp);
                })
                .error(function () {
                  deferred.reject();
                });

        help[lang] = deferred.promise;
      }

      return help[lang];
    }

    function getLangs() {
      return langs_promise.promise;
    }
  }
})();


(function () {
  'use strict';

  angular.module('helpApp').controller('HelpCtrl', HelpCtrl);

  function HelpCtrl($location, $scope, helpService) {
    var vm = this;
    vm.currentId = 1;
    vm.currentLang;
    vm.currentText = {};
    vm.langs = [];
    vm.texts = [];
    vm.idToIndex = {};

    vm.goto = goto;

    initPage();

    function goto(id) {
      $location.search('id', id);
    };

    function initPage() {
      helpService.getLangs().then(function (langs) {
        vm.langs = langs;
        updatePage();

        $scope.$on('$locationChangeSuccess', function () {
          updatePage();
        });
      });
    }

    function updatePage() {
      var params = $location.search();
      vm.currentId = params.id || 1;
      vm.currentLang = params.lang || vm.langs[0];

      if (vm.langs.indexOf(vm.currentLang) === -1) {
        vm.currentLang = vm.langs[0];
      }

      helpService.getText(vm.currentLang)
              .then(function (data) {
                vm.texts = data.texts;
                vm.idToIndex = data.idToIndex;
                var index = vm.idToIndex[vm.currentId];
                if (index !== undefined) {
                    vm.currentText = vm.texts[index];
                } else {
                    window.location.hash = '?id=1&lang=' + vm.currentLang;
                }
              });
    }
  }
})();
